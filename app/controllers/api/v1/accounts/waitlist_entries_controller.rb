class Api::V1::Accounts::WaitlistEntriesController < Api::V1::Accounts::BaseController
  include WaitlistEnabledGuard

  before_action :fetch_entry, except: [:index, :create, :next]
  before_action :check_authorization

  def index
    @entries = policy_scope(Current.account.waitlist_entries).oldest_first.includes(:contact, :professional, :offered_professional)
    @entries = @entries.where(status: params[:status]) if params[:status].present?
    @entries = @entries.where(specialty: params[:specialty]) if params[:specialty].present?
    @entries = @entries.where(professional_id: params[:professional_id]) if params[:professional_id].present?
  end

  def show; end

  def create
    @entry = Current.account.waitlist_entries.create!(permitted_params)
    render :show
  end

  # First patient in line for a professional's slot, skipping those who already declined that slot.
  def next
    professional = Current.account.professionals.find(params.require(:professional_id))
    entries = Current.account.waitlist_entries.waiting.matching(professional).where('expires_at > ?', Time.current)
    entries = entries.where.not('declined_slots @> ?', [WaitlistEntry.slot_key(professional, slot_starts_at)].to_json) if slot_starts_at
    @entry = entries.oldest_first.includes(:contact, :professional).first

    return head :no_content unless @entry

    render :show
  end

  def offer
    professional = Current.account.professionals.find(params.require(:professional_id))
    @entry.offer!(professional, slot_starts_at)
    render :show
  end

  def accept
    @entry.accept!
    render :show
  end

  def decline
    @entry.release_offer!
    render :show
  end

  def destroy
    @entry.cancelled!
    head :ok
  end

  private

  def fetch_entry
    @entry = Current.account.waitlist_entries.find(params[:id])
  end

  def permitted_params
    params.require(:waitlist_entry).permit(:contact_id, :professional_id, :specialty)
  end

  def slot_starts_at
    return if params[:slot_starts_at].blank?

    Time.zone.parse(params[:slot_starts_at].to_s)
  rescue ArgumentError
    nil
  end
end
