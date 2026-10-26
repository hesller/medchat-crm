class Api::V1::Accounts::Pipelines::BaseController < Api::V1::Accounts::BaseController
  include PipelineFeatureGate

  before_action :pipeline

  private

  def pipeline
    @pipeline ||= Current.account.pipelines.find(params[:pipeline_id])
  end
end
