# The pipeline is sold per plan: a superadmin turns it on for each account.
module PipelineEnabledGuard
  extend ActiveSupport::Concern

  included do
    before_action :ensure_pipeline_enabled
  end

  private

  def ensure_pipeline_enabled
    return if Current.account.pipeline_enabled

    render json: { error: I18n.t('pipelines.disabled') }, status: :forbidden
  end
end
