class CreateEncaixes < ActiveRecord::Migration[7.2]
  def change
    create_table :encaixes do |t|
      t.references :account, null: false, index: false
      t.references :professional, null: false, index: false
      t.references :contact, null: false, index: true
      t.datetime :starts_at, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :encaixes, [:professional_id, :starts_at]
    add_index :encaixes, [:account_id, :status]
  end
end
