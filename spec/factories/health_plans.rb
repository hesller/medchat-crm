# frozen_string_literal: true

FactoryBot.define do
  factory :health_plan do
    account
    sequence(:name) { |n| "Plano #{n}" }
  end
end
