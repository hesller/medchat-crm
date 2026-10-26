class Api::V1::Accounts::Pipelines::CardsController < Api::V1::Accounts::Pipelines::BaseController
  before_action :fetch_card, only: [:update, :destroy, :move]
  before_action -> { check_authorization(PipelineCard) }

  def create
    @card = PipelineCard.create!(card_params.merge(pipeline_stage: fetch_stage(params.require(:card).require(:pipeline_stage_id))))
  end

  def update
    @card.update!(card_params)
  end

  def destroy
    @card.destroy!
    head :ok
  end

  def move
    @card.move_to!(fetch_stage(params.require(:pipeline_stage_id)), params.require(:position).to_i)
    render :update
  end

  private

  def fetch_card
    @card = @pipeline.cards.find(params[:id])
  end

  def fetch_stage(id)
    @pipeline.stages.find(id)
  end

  def card_params
    params.require(:card).permit(:title, :description, :value, :contact_id, :assignee_id)
  end
end
