class CreatePipelines < ActiveRecord::Migration[7.1]
  def change
    create_pipelines
    create_pipeline_stages
    create_pipeline_items
  end

  private

  def create_pipelines
    create_table :pipelines do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :pipelines, [:account_id, :name], unique: true
  end

  def create_pipeline_stages
    create_table :pipeline_stages do |t|
      t.bigint :account_id, null: false
      t.bigint :pipeline_id, null: false
      t.string :name, null: false
      t.string :color, null: false, default: '#1f93ff'
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :pipeline_stages, :account_id
    add_index :pipeline_stages, [:pipeline_id, :position]
  end

  def create_pipeline_items
    create_table :pipeline_items do |t|
      t.bigint :account_id, null: false
      t.bigint :pipeline_id, null: false
      t.bigint :pipeline_stage_id, null: false
      t.bigint :conversation_id, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :pipeline_items, :account_id
    add_index :pipeline_items, :conversation_id
    add_index :pipeline_items, [:pipeline_id, :conversation_id], unique: true
    add_index :pipeline_items, [:pipeline_stage_id, :position]
  end
end
