class Api::V1::Accounts::Pipelines::StagesController < Api::V1::Accounts::Pipelines::BaseController
  before_action { authorize(@pipeline, :update?) }
  before_action :fetch_stage, except: [:create]

  def create
    @stage = @pipeline.stages.create!(permitted_params.except(:position))
  end

  def update
    @stage.update!(permitted_params.except(:position))
    @stage.move_to!(permitted_params[:position]) if permitted_params.key?(:position)
  end

  def destroy
    @stage.destroy!
    Pipeline.renumber!(@pipeline.stages.to_a)
    head :ok
  end

  private

  def fetch_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def permitted_params
    params.require(:stage).permit(:name, :color, :position)
  end
end
