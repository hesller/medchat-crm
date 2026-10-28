# == Schema Information
#
# Table name: waitlist_entries
#
#  id                     :bigint           not null, primary key
#  declined_slots         :jsonb            not null
#  expires_at             :datetime         not null
#  offer_expires_at       :datetime
#  offered_at             :datetime
#  offered_slot_starts_at :datetime
#  specialty              :string           not null
#  status                 :integer          default("waiting"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  contact_id             :bigint           not null
#  offered_professional_id :bigint
#  professional_id        :bigint
#
# Indexes
#
#  index_waitlist_entries_on_account_id_and_status_and_specialty  (account_id,status,specialty)
#  index_waitlist_entries_on_active_offer_slot                    (offered_professional_id,offered_slot_starts_at) UNIQUE WHERE (status = 1)
#  index_waitlist_entries_on_contact_id_and_status                (contact_id,status)
#  index_waitlist_entries_on_offer_expires_at                     (offer_expires_at) WHERE (status = 1)
#
class WaitlistEntry < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :professional, optional: true
  belongs_to :offered_professional, class_name: 'Professional', optional: true

  enum :status, { waiting: 0, offered: 1, scheduled: 2, expired: 3, cancelled: 4 }

  validates :specialty, presence: true
  validate :contact_and_professional_belong_to_account
  validate :single_queued_entry, on: :create
  with_options if: -> { offered? && will_save_change_to_status? } do
    validate :offer_allowed
    validate :offer_slot_free
    validate :outside_quiet_hours
  end

  before_validation :inherit_specialty, :set_expiry, on: :create

  scope :queued, -> { where(status: [:waiting, :offered]) }
  scope :oldest_first, -> { order(:created_at) }

  # Entries that asked for this professional, or for any professional of the same specialty.
  scope :matching, lambda { |professional|
    where(specialty: professional.specialty, professional_id: [professional.id, nil])
  }

  def self.slot_key(professional, slot_starts_at)
    "#{professional.id}:#{slot_starts_at.utc.iso8601}"
  end

  def offer!(professional, slot_starts_at)
    update!(
      status: :offered,
      offered_professional: professional,
      offered_slot_starts_at: slot_starts_at,
      offered_at: Time.current,
      offer_expires_at: account.waitlist_offer_timeout_minutes.minutes.from_now
    )
  end

  def accept!
    unless offered? && offer_expires_at.future?
      errors.add(:base, :offer_expired)
      raise ActiveRecord::RecordInvalid, self
    end

    update!(status: :scheduled)
  end

  # The declined slot is remembered so the same patient is not offered it again.
  def release_offer!
    update!(
      status: :waiting,
      declined_slots: declined_slots | [self.class.slot_key(offered_professional, offered_slot_starts_at)],
      offered_professional: nil,
      offered_slot_starts_at: nil,
      offered_at: nil,
      offer_expires_at: nil
    )
  end

  private

  def inherit_specialty
    self.specialty = professional.specialty if professional
  end

  def set_expiry
    self.expires_at ||= account.waitlist_entry_validity_days.days.from_now
  end

  def contact_and_professional_belong_to_account
    errors.add(:contact, :invalid) if contact && contact.account_id != account_id
    errors.add(:professional, :invalid) if professional && professional.account_id != account_id
  end

  def single_queued_entry
    return unless self.class.queued.exists?(contact_id: contact_id, specialty: specialty, professional_id: professional_id)

    errors.add(:base, :already_queued)
  end

  def offer_allowed
    return errors.add(:offered_slot_starts_at, :invalid) unless offered_professional && offered_slot_starts_at&.future?

    errors.add(:offered_professional, :invalid) unless fits_request?
    errors.add(:offered_slot_starts_at, :declined) if declined_slots.include?(self.class.slot_key(offered_professional, offered_slot_starts_at))
  end

  def offer_slot_free
    same_slot = { offered_professional_id: offered_professional_id, offered_slot_starts_at: offered_slot_starts_at }
    errors.add(:offered_slot_starts_at, :taken) if self.class.offered.where.not(id: id).exists?(same_slot)
  end

  def outside_quiet_hours
    errors.add(:base, :quiet_hours) if quiet_hours?
  end

  def fits_request?
    offered_professional.account_id == account_id && offered_professional.specialty == specialty &&
      (professional_id.nil? || professional_id == offered_professional_id)
  end

  def quiet_hours?
    start_at = account.waitlist_quiet_hours_start
    end_at = account.waitlist_quiet_hours_end
    return false if start_at.blank? || end_at.blank?

    now = Time.current.in_time_zone(account.reporting_timezone.presence || 'UTC').strftime('%H:%M')
    start_at <= end_at ? (start_at...end_at).cover?(now) : (now >= start_at || now < end_at)
  end
end
