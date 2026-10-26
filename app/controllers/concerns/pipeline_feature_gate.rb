module PipelineFeatureGate
  extend ActiveSupport::Concern

  FEATURE = 'pipeline'.freeze

  included do
    before_action :ensure_pipeline_feature_enabled
  end

  private

  def ensure_pipeline_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?(FEATURE)
  end
end
