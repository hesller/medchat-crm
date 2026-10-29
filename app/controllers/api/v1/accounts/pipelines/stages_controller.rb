class Api::V1::Accounts::Pipelines::StagesController < Api::V1::Accounts::Pipelines::BaseController
  before_action :fetch_stage, only: [:update, :destroy]
  before_action -> { check_authorization(PipelineStage) }

  def create
    @stage = @pipeline.stages.create!(stage_params)
  end

  def update
    @stage.update!(stage_params)
  end

  def destroy
    @stage.destroy!
    head :ok
  end

  # Receives every stage id of the pipeline, in the new order.
  def reorder
    ids = params.require(:ids).map(&:to_i)
    return render_could_not_create_error(I18n.t('pipelines.invalid_stage_order')) unless ids.sort == @pipeline.stages.ids.sort

    PipelineStage.write_positions!(ids)
    @stages = @pipeline.stages.reload
  end

  private

  def fetch_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :color)
  end
end
