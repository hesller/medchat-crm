class PipelineCard < ApplicationRecord
  include SequencedPositions

  belongs_to :account
  belongs_to :pipeline
  belongs_to :pipeline_stage
  belongs_to :contact, optional: true
  belongs_to :assignee, class_name: 'User', optional: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :contact_in_account
  validate :assignee_in_account

  # The stage decides where the card lives, so the pipeline and account can never disagree with it.
  before_validation :inherit_from_stage
  before_create :append_to_end

  # Places the card at `index` inside `stage`, shifting the cards already there.
  def move_to!(stage, index)
    transaction do
      update!(pipeline_stage: stage)
      ids = stage.cards.where.not(id: id).pluck(:id)
      ids.insert(index.clamp(0, ids.size), id)
      self.class.write_positions!(ids)
    end
    reload
  end

  private

  def inherit_from_stage
    return if pipeline_stage.nil?

    self.pipeline = pipeline_stage.pipeline
    self.account = pipeline_stage.account
  end

  def append_to_end
    self.position = pipeline_stage.cards.maximum(:position).to_i + 1
  end

  def contact_in_account
    errors.add(:contact, :invalid) if contact && contact.account_id != account_id
  end

  def assignee_in_account
    errors.add(:assignee, :invalid) if assignee && !account&.users&.exists?(id: assignee.id)
  end
end
