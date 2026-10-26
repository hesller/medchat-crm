require 'rails_helper'

RSpec.describe PipelineItem do
  let(:pipeline) { create(:pipeline) }
  let(:new_stage) { create(:pipeline_stage, pipeline: pipeline) }
  let(:won_stage) { create(:pipeline_stage, pipeline: pipeline) }
  let!(:items) { create_list(:pipeline_item, 3, stage: new_stage) }

  it 'appends new cards to the end of the stage' do
    expect(items.map { |item| item.reload.position }).to eq([0, 1, 2])
  end

  it 'rejects a conversation that is already in the pipeline' do
    duplicate = build(:pipeline_item, stage: won_stage, conversation: items.first.conversation)

    expect(duplicate).not_to be_valid
  end

  it 'rejects a conversation from another account' do
    item = build(:pipeline_item, stage: new_stage, conversation: create(:conversation))

    expect(item).not_to be_valid
  end

  describe '#move_to!' do
    it 'reorders cards inside the same stage' do
      items.last.move_to!(new_stage, 0)

      expect(new_stage.items.reload.map(&:id)).to eq([items[2].id, items[0].id, items[1].id])
    end

    it 'moves a card to another stage and closes the gap it leaves' do
      existing = create(:pipeline_item, stage: won_stage)

      items.first.move_to!(won_stage, 0)

      expect(won_stage.items.reload.map { |item| [item.id, item.position] }).to eq([[items[0].id, 0], [existing.id, 1]])
      expect(new_stage.items.reload.map { |item| [item.id, item.position] }).to eq([[items[1].id, 0], [items[2].id, 1]])
    end
  end
end
