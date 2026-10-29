# == Schema Information
#
# Table name: encaixes
#
#  id              :bigint           not null, primary key
#  starts_at       :datetime         not null
#  status          :integer          default("scheduled"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  contact_id      :bigint           not null
#  professional_id :bigint           not null
#
# Indexes
#
#  index_encaixes_on_account_id_and_status       (account_id,status)
#  index_encaixes_on_contact_id                  (contact_id)
#  index_encaixes_on_professional_id_and_starts_at  (professional_id,starts_at)
#
class Encaixe < ApplicationRecord
  belongs_to :account
  belongs_to :professional
  belongs_to :contact

  enum :status, { scheduled: 0, cancelled: 1 }

  validates :starts_at, presence: true
  validate :contact_and_professional_belong_to_account
  validate :within_daily_limit, on: :create

  scope :on_day, ->(day, time_zone) { where(starts_at: day.in_time_zone(time_zone).all_day) }

  # The row lock serializes concurrent bookings for the same professional, so two
  # attendants cannot both take the last encaixe of the day.
  def self.book!(attributes)
    professional = attributes.fetch(:professional)
    transaction do
      professional.lock!
      create!(attributes)
    end
  end

  private

  def contact_and_professional_belong_to_account
    errors.add(:contact, :invalid) if contact && contact.account_id != account_id
    errors.add(:professional, :invalid) if professional && professional.account_id != account_id
  end

  def within_daily_limit
    return unless professional && starts_at

    limit = professional.encaixe_daily_limit.to_i
    time_zone = account.reporting_timezone.presence || 'UTC'
    taken = professional.encaixes.scheduled.on_day(starts_at.in_time_zone(time_zone), time_zone).count
    errors.add(:base, :limit_reached) if taken >= limit
  end
end
