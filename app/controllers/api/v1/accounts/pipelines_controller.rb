class Api::V1::Accounts::PipelinesController < Api::V1::Accounts::BaseController
  include PipelineFeatureGate

  before_action :fetch_pipeline, except: [:index, :create]
  before_action :check_authorization

  def index
    @pipelines = Current.account.pipelines.order(:name)
  end

  def show
    @items = @pipeline.items.where(conversation_id: visible_conversations.select(:id))
                      .includes(conversation: [:contact, :assignee, :inbox])
                      .order(:position, :id)
                      .group_by(&:pipeline_stage_id)
  end

  def create
    ActiveRecord::Base.transaction do
      @pipeline = Current.account.pipelines.create!(name: permitted_params[:name])
      Array(params[:stage_names]).compact_blank.each { |name| @pipeline.stages.create!(name: name) }
    end
  end

  def update
    @pipeline.update!(name: permitted_params[:name])
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.pipelines.find(params[:id])
  end

  def check_authorization
    authorize(@pipeline || Pipeline)
  end

  # Agents only see the cards of conversations they could open from their own conversation list.
  def visible_conversations
    Conversations::PermissionFilterService.new(Current.account.conversations, Current.user, Current.account).perform
  end

  def permitted_params
    params.require(:pipeline).permit(:name)
  end
end
