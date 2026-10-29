class Api::V1::Accounts::ProfessionalsController < Api::V1::Accounts::BaseController
  before_action :fetch_professional, except: [:index, :create]
  before_action :check_authorization

  def index
    @professionals = policy_scope(Current.account.professionals)
    @professionals = @professionals.active if params[:active] == 'true'
    @professionals = @professionals.where(specialty: params[:specialty]) if params[:specialty].present?
  end

  def show; end

  def create
    @professional = Current.account.professionals.create!(permitted_params)
  end

  def update
    @professional.update!(permitted_params)
  end

  def destroy
    @professional.destroy!
    head :ok
  end

  private

  def fetch_professional
    @professional = Current.account.professionals.find(params[:id])
  end

  def permitted_params
    params.require(:professional).permit(:name, :specialty, :external_calendar_id, :active, :encaixe_daily_limit)
  end
end
