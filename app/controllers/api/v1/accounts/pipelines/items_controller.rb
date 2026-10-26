class Api::V1::Accounts::Pipelines::ItemsController < Api::V1::Accounts::Pipelines::BaseController
  before_action { authorize(@pipeline, :manage_items?) }
  before_action :fetch_item, except: [:create]

  def create
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize(conversation, :show?)
    @item = @pipeline.items.create!(stage: stage, conversation: conversation)
  end

  def update
    @item.move_to!(stage, params.require(:position))
  end

  def destroy
    @item.destroy!
    Pipeline.renumber!(@item.stage.items.reload.to_a)
    head :ok
  end

  private

  def fetch_item
    @item = @pipeline.items.find(params[:id])
    authorize(@item.conversation, :show?)
  end

  def stage
    @pipeline.stages.find(params.require(:pipeline_stage_id))
  end
end
