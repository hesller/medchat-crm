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
#  external_booking_uid :string
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

  CALENDAR_TIMEOUT = 15

  enum :status, { scheduled: 0, cancelled: 1 }

  validates :starts_at, presence: true
  validate :contact_and_professional_belong_to_account
  validate :professional_has_encaixe_calendar, on: :create
  validate :within_daily_limit, on: :create

  scope :on_day, ->(day, time_zone) { where(starts_at: day.in_time_zone(time_zone).all_day) }

  # The row lock serializes concurrent bookings for the same professional, so two
  # attendants cannot both take the last encaixe of the day.
  def self.book!(attributes)
    professional = attributes.fetch(:professional)
    encaixe = transaction do
      professional.lock!
      create!(attributes)
    end
    encaixe.book_in_calendar!
  end

  # The row is already counted against the daily limit while the calendar answers, so
  # a refusal has to give the vaga back.
  def book_in_calendar!
    response = HTTParty.post(
      ENV.fetch('ENCAIXE_WEBHOOK_URL'),
      body: { calendar_id: professional.encaixe_calendar_id, starts_at: starts_at.iso8601,
              name: contact.name, phone_number: contact.phone_number }.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: CALENDAR_TIMEOUT
    )
    uid = response.parsed_response['uid'] if response.success?
    refuse_calendar! if uid.blank?

    update!(external_booking_uid: uid)
    self
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, SocketError
    refuse_calendar!
  end

  private

  def contact_and_professional_belong_to_account
    errors.add(:contact, :invalid) if contact && contact.account_id != account_id
    errors.add(:professional, :invalid) if professional && professional.account_id != account_id
  end

  def refuse_calendar!
    cancelled!
    errors.add(:base, :calendar_unavailable)
    raise ActiveRecord::RecordInvalid, self
  end

  def professional_has_encaixe_calendar
    errors.add(:professional, :no_encaixe_calendar) if professional && professional.encaixe_calendar_id.blank?
  end

  def within_daily_limit
    return unless professional && starts_at

    limit = professional.encaixe_daily_limit.to_i
    time_zone = account.reporting_timezone.presence || 'UTC'
    taken = professional.encaixes.scheduled.on_day(starts_at.in_time_zone(time_zone), time_zone).count
    errors.add(:base, :limit_reached) if taken >= limit
  end
end
