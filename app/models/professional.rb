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
#
# Indexes
#
#  index_professionals_on_account_id_and_external_calendar_id  (account_id,external_calendar_id) UNIQUE WHERE (external_calendar_id IS NOT NULL)
#  index_professionals_on_account_id_and_specialty             (account_id,specialty)
#
class Professional < ApplicationRecord
  belongs_to :account
  has_many :professional_health_plans, dependent: :destroy
  has_many :health_plans, through: :professional_health_plans

  validates :name, presence: true
  validates :specialty, presence: true
  validates :external_calendar_id, uniqueness: { scope: :account_id }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :accepting_health_plan, lambda { |health_plan_id|
    where(id: ProfessionalHealthPlan.where(health_plan_id: health_plan_id).select(:professional_id))
  }
  default_scope { order(:name) }
end
