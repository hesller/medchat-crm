class PipelineStage < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline
  has_many :items, -> { order(:position, :id) }, class_name: 'PipelineItem', dependent: :delete_all, inverse_of: :stage

  validates :name, presence: true

  before_validation :ensure_account_id
  before_create :append_to_end

  # Places the stage at `index` among its pipeline's stages and renumbers the rest, so the board order is
  # always the dense 0..n-1 sequence the client renders.
  def move_to!(index)
    siblings = pipeline.stages.where.not(id: id).to_a
    Pipeline.renumber!(siblings.insert(index.to_i.clamp(0, siblings.size), self))
  end

  private

  def ensure_account_id
    self.account_id = pipeline&.account_id
  end

  def append_to_end
    self.position = (pipeline.stages.maximum(:position) || -1) + 1
  end
end
