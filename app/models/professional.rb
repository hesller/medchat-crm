# == Schema Information
#
# Table name: professionals
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE), not null
#  name                 :string           not null
#  specialty            :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  external_calendar_id :string
#  encaixe_calendar_id  :string
#  encaixe_daily_limit  :integer
#
# Indexes
#
#  index_professionals_on_account_id_and_external_calendar_id  (account_id,external_calendar_id) UNIQUE WHERE (external_calendar_id IS NOT NULL)
#  index_professionals_on_account_id_and_specialty             (account_id,specialty)
#
class Professional < ApplicationRecord
  belongs_to :account
  has_many :encaixes, dependent: :destroy_async

  validates :name, presence: true
  validates :specialty, presence: true
  validates :encaixe_daily_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :external_calendar_id, uniqueness: { scope: :account_id }, allow_nil: true

  scope :active, -> { where(active: true) }
  default_scope { order(:name) }
end
