require 'rails_helper'

RSpec.describe 'Pipeline cards API', type: :request do
  let(:account) { create(:account, pipeline_enabled: true) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:pipeline, account: account) }
  let(:lead) { create(:pipeline_stage, pipeline: pipeline) }
  let(:won) { create(:pipeline_stage, pipeline: pipeline) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/pipelines/#{pipeline.id}/cards" }

  describe 'POST /cards' do
    it 'creates the card at the end of the stage' do
      existing = create(:pipeline_card, pipeline_stage: lead)
      contact = create(:contact, account: account)

      params = { card: { title: 'Implant', value: '3500.90', pipeline_stage_id: lead.id, contact_id: contact.id, assignee_id: agent.id } }

      post base_url, params: params, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      card = PipelineCard.last
      expect(card).to have_attributes(title: 'Implant', pipeline_id: pipeline.id, account_id: account.id, contact_id: contact.id,
                                      assignee_id: agent.id)
      expect(card.position).to be > existing.reload.position
      expect(response.parsed_body['payload']['value']).to eq(3500.9)
    end

    it 'rejects a contact from another account' do
      post base_url, params: { card: { title: 'Implant', pipeline_stage_id: lead.id, contact_id: create(:contact).id } },
                     headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(PipelineCard.count).to eq(0)
    end

    it 'rejects an assignee who is not a member of the account' do
      post base_url, params: { card: { title: 'Implant', pipeline_stage_id: lead.id, assignee_id: create(:user).id } },
                     headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects a stage from another pipeline' do
      other_stage = create(:pipeline_stage, pipeline: create(:pipeline, account: account))

      post base_url, params: { card: { title: 'Implant', pipeline_stage_id: other_stage.id } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /cards/:id' do
    it 'updates the card details' do
      card = create(:pipeline_card, pipeline_stage: lead)

      patch "#{base_url}/#{card.id}", params: { card: { title: 'Renamed', description: 'Call back on Monday', value: nil } },
                                      headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(card.reload).to have_attributes(title: 'Renamed', description: 'Call back on Monday', value: nil)
    end
  end

  describe 'PATCH /cards/:id/move' do
    it 'moves the card into another stage at the given position' do
      moving = create(:pipeline_card, pipeline_stage: lead)
      first, second = create_list(:pipeline_card, 2, pipeline_stage: won)

      patch "#{base_url}/#{moving.id}/move", params: { pipeline_stage_id: won.id, position: 1 }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to include('pipeline_stage_id' => won.id, 'position' => 1)
      expect(won.cards.reload.map(&:id)).to eq([first.id, moving.id, second.id])
      expect(lead.cards.reload).to be_empty
    end

    it 'reorders the card inside its own stage' do
      first, second, third = create_list(:pipeline_card, 3, pipeline_stage: lead)

      patch "#{base_url}/#{third.id}/move", params: { pipeline_stage_id: lead.id, position: 0 }, headers: agent.create_new_auth_token, as: :json

      expect(lead.cards.reload.map(&:id)).to eq([third.id, first.id, second.id])
    end
  end

  describe 'DELETE /cards/:id' do
    it 'deletes the card' do
      card = create(:pipeline_card, pipeline_stage: lead)

      delete "#{base_url}/#{card.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(PipelineCard.exists?(card.id)).to be false
    end
  end
end
