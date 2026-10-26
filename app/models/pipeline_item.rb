class PipelineItem < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline
  belongs_to :stage, class_name: 'PipelineStage', foreign_key: :pipeline_stage_id, inverse_of: :items
  belongs_to :conversation

  validates :conversation_id, uniqueness: { scope: :pipeline_id }
  validate :stage_belongs_to_pipeline
  validate :conversation_belongs_to_account

  before_validation :ensure_pipeline_and_account
  before_create :append_to_end

  # Moves the card to `index` inside `target_stage`, renumbering both the column it leaves and the one it
  # enters so each stays a dense 0..n-1 sequence.
  def move_to!(target_stage, index)
    source_stage = stage
    transaction do
      update!(stage: target_stage)
      siblings = target_stage.items.where.not(id: id).to_a
      Pipeline.renumber!(siblings.insert(index.to_i.clamp(0, siblings.size), self))
      Pipeline.renumber!(source_stage.items.to_a) unless source_stage.id == target_stage.id
    end
  end

  private

  def ensure_pipeline_and_account
    self.pipeline_id ||= stage&.pipeline_id
    self.account_id = pipeline&.account_id
  end

  def append_to_end
    self.position = (stage.items.maximum(:position) || -1) + 1
  end

  def stage_belongs_to_pipeline
    return if stage.blank? || stage.pipeline_id == pipeline_id

    errors.add(:pipeline_stage_id, :invalid)
  end

  def conversation_belongs_to_account
    return if conversation.blank? || conversation.account_id == account_id

    errors.add(:conversation_id, :invalid)
  end
end
