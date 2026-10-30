# == Schema Information
#
# Table name: professional_health_plans
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  health_plan_id  :bigint           not null
#  professional_id :bigint           not null
#
# Indexes
#
#  index_professional_health_plans_on_health_plan_id  (health_plan_id)
#  index_professional_health_plans_uniqueness         (professional_id,health_plan_id) UNIQUE
#
class ProfessionalHealthPlan < ApplicationRecord
  belongs_to :professional
  belongs_to :health_plan

  validates :health_plan_id, uniqueness: { scope: :professional_id }
end
