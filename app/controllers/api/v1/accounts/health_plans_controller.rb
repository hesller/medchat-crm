class Api::V1::Accounts::HealthPlansController < Api::V1::Accounts::BaseController
  before_action :fetch_health_plan, except: [:index, :create]
  before_action :check_authorization

  def index
    @health_plans = policy_scope(Current.account.health_plans)
    @health_plans = @health_plans.active if params[:active] == 'true'
    @health_plans = @health_plans.name_matching(params[:q]) if params[:q].present?
  end

  def show; end

  def create
    @health_plan = Current.account.health_plans.create!(permitted_params)
  end

  def update
    @health_plan.update!(permitted_params)
  end

  def destroy
    @health_plan.destroy!
    head :ok
  end

  private

  def fetch_health_plan
    @health_plan = Current.account.health_plans.find(params[:id])
  end

  def permitted_params
    params.require(:health_plan).permit(:name, :active)
  end
end
