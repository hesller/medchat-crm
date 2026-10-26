class CreatePipelines < ActiveRecord::Migration[7.2]
  def change
    create_pipelines
    create_pipeline_stages
    create_pipeline_cards
  end

  private

  def create_pipelines
    create_table :pipelines do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end

  def create_pipeline_stages
    create_table :pipeline_stages do |t|
      t.references :account, null: false, index: true
      t.references :pipeline, null: false, index: true, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: '#1F93FF'
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end

  def create_pipeline_cards
    create_table :pipeline_cards do |t|
      t.references :account, null: false, index: true
      t.references :pipeline, null: false, index: true, foreign_key: true
      t.references :pipeline_stage, null: false, index: false, foreign_key: true
      t.references :contact, null: true, index: true, foreign_key: { on_delete: :nullify }
      t.references :assignee, null: true, index: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :title, null: false
      t.text :description
      t.decimal :value, precision: 15, scale: 2
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :pipeline_cards, [:pipeline_stage_id, :position]
  end
end
