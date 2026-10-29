class Api::V1::Accounts::EncaixesController < Api::V1::Accounts::BaseController
  before_action :fetch_encaixe, only: :destroy
  before_action :check_authorization

  def index
    @encaixes = policy_scope(Current.account.encaixes).scheduled.order(:starts_at).includes(:contact, :professional)
    @encaixes = @encaixes.where(professional_id: params[:professional_id]) if params[:professional_id].present?
    @encaixes = @encaixes.on_day(Date.parse(params[:date]), time_zone) if params[:date].present?
  end

  def create
    @encaixe = Encaixe.book!(
      account: Current.account,
      professional: Current.account.professionals.find(params.require(:professional_id)),
      contact: Current.account.contacts.find(params.require(:contact_id)),
      starts_at: params.require(:starts_at)
    )
    render :show
  end

  def destroy
    @encaixe.cancelled!
    render :show
  end

  private

  def fetch_encaixe
    @encaixe = Current.account.encaixes.find(params[:id])
  end

  def time_zone
    Current.account.reporting_timezone.presence || 'UTC'
  end
end
