class PipelineStage < ApplicationRecord
  include SequencedPositions

  belongs_to :account
  belongs_to :pipeline
  has_many :cards, -> { order(:position, :id) }, class_name: 'PipelineCard', dependent: :delete_all, inverse_of: :pipeline_stage

  validates :name, presence: true, length: { maximum: 255 }
  validates :color, format: { with: /\A#\h{6}\z/ }

  before_validation :inherit_account, on: :create
  # Nested stages are saved one by one after their pipeline, so they keep the order they were sent in.
  before_create :append_to_end

  private

  def inherit_account
    self.account ||= pipeline&.account
  end

  def append_to_end
    self.position = pipeline.stages.maximum(:position).to_i + 1
  end
end
