# frozen_string_literal: true

FactoryBot.define do
  factory :professional do
    account
    sequence(:name) { |n| "Dr. Professional #{n}" }
    specialty { 'Cardiologia' }
  end
end
