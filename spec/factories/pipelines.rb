FactoryBot.define do
  factory :pipeline do
    account
    sequence(:name) { |n| "Pipeline #{n}" }
  end

  factory :pipeline_stage do
    pipeline
    sequence(:name) { |n| "Stage #{n}" }
  end

  factory :pipeline_item do
    stage factory: :pipeline_stage
    conversation { association :conversation, account: stage.pipeline.account }
  end
end
