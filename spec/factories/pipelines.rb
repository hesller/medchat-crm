# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline do
    account
    sequence(:name) { |n| "Pipeline #{n}" }
  end

  factory :pipeline_stage do
    pipeline
    sequence(:name) { |n| "Stage #{n}" }
  end

  factory :pipeline_card do
    pipeline_stage
    sequence(:title) { |n| "Deal #{n}" }
  end
end
