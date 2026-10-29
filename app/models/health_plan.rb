# == Schema Information
#
# Table name: health_plans
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE), not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_health_plans_on_account_id_and_lower_name  (account_id, lower((name)::text)) UNIQUE
#
class HealthPlan < ApplicationRecord
  belongs_to :account
  has_many :professional_health_plans, dependent: :destroy
  has_many :professionals, through: :professional_health_plans

  validates :name, presence: true
  validates :name, uniqueness: { scope: :account_id, case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :name_matching, ->(text) { where('health_plans.name ILIKE ?', "%#{sanitize_sql_like(text.strip)}%") }
  default_scope { order(:name) }
end
