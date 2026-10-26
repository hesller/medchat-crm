class Pipeline < ApplicationRecord
  belongs_to :account
  # Cards go first: they reference both the pipeline and its stages.
  has_many :cards, class_name: 'PipelineCard', dependent: :delete_all, inverse_of: :pipeline
  has_many :stages, -> { order(:position, :id) }, class_name: 'PipelineStage', dependent: :delete_all, inverse_of: :pipeline

  accepts_nested_attributes_for :stages

  validates :name, presence: true, length: { maximum: 255 }

  before_create :append_to_end

  scope :ordered, -> { order(:position, :id) }

  private

  def append_to_end
    self.position = account.pipelines.maximum(:position).to_i + 1
  end
end
