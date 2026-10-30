class CreateHealthPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :health_plans do |t|
      t.references :account, null: false, index: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :health_plans, 'account_id, lower(name)', unique: true, name: 'index_health_plans_on_account_id_and_lower_name'

    create_table :professional_health_plans do |t|
      t.references :professional, null: false, index: false
      t.references :health_plan, null: false, index: true
      t.timestamps
    end
    add_index :professional_health_plans, [:professional_id, :health_plan_id], unique: true, name: 'index_professional_health_plans_uniqueness'
  end
end
