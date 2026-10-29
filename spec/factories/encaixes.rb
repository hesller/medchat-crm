# frozen_string_literal: true

FactoryBot.define do
  factory :encaixe do
    account
    professional { association :professional, account: account, encaixe_daily_limit: 2, encaixe_calendar_id: '42' }
    contact { association :contact, account: account }
    starts_at { 1.day.from_now.change(hour: 12, min: 30) }
  end
end
