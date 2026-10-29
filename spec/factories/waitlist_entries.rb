# frozen_string_literal: true

FactoryBot.define do
  factory :waitlist_entry do
    account
    contact { association :contact, account: account }
    specialty { 'Cardiologia' }
  end
end
