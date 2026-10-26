class Pipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, -> { order(:position, :id) }, class_name: 'PipelineStage', dependent: :destroy, inverse_of: :pipeline
  has_many :items, class_name: 'PipelineItem', dependent: :delete_all, inverse_of: :pipeline

  validates :name, presence: true, uniqueness: { scope: :account_id }

  # Stages and cards are ordered by a dense 0..n-1 `position`; this writes the order of `records` back.
  def self.renumber!(records)
    transaction do
      records.each_with_index { |record, position| record.update_columns(position: position) } # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
