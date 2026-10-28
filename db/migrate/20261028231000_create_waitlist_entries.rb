class CreateWaitlistEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :waitlist_entries do |t|
      t.references :account, null: false, index: false
      t.references :contact, null: false, index: false
      t.references :professional, null: true, index: false
      t.references :offered_professional, null: true, index: false
      t.string :specialty, null: false
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :offered_at
      t.datetime :offered_slot_starts_at
      t.datetime :offer_expires_at
      t.jsonb :declined_slots, null: false, default: []
      t.timestamps
    end

    add_index :waitlist_entries, [:account_id, :status, :specialty]
    add_index :waitlist_entries, [:contact_id, :status]
    add_index :waitlist_entries, :offer_expires_at, where: 'status = 1'
    add_index :waitlist_entries, [:offered_professional_id, :offered_slot_starts_at], unique: true, where: 'status = 1',
                                                                                       name: 'index_waitlist_entries_on_active_offer_slot'
  end
end
