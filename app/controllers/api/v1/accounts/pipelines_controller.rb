class Api::V1::Accounts::PipelinesController < Api::V1::Accounts::BaseController
  include PipelineEnabledGuard

  before_action :fetch_pipeline, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @pipelines = Current.account.pipelines.ordered.includes(:stages)
  end

  def show
    @stages = @pipeline.stages.includes(cards: [{ contact: { avatar_attachment: :blob } }, { assignee: { avatar_attachment: :blob } }])
  end

  def create
    @pipeline = Current.account.pipelines.create!(create_params)
  end

  def update
    @pipeline.update!(params.require(:pipeline).permit(:name))
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.pipelines.find(params[:id])
  end

  def create_params
    params.require(:pipeline).permit(:name, stages_attributes: [:name, :color])
  end
end
