class CreateProfessionals < ActiveRecord::Migration[7.2]
  def change
    create_table :professionals do |t|
      t.references :account, null: false, index: false
      t.string :name, null: false
      t.string :specialty, null: false
      t.string :external_calendar_id
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :professionals, [:account_id, :specialty]
    add_index :professionals, [:account_id, :external_calendar_id], unique: true, where: 'external_calendar_id IS NOT NULL'
  end
end
