require 'rails_helper'

RSpec.describe 'Pipeline Items API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:pipeline) { create(:pipeline, account: account) }
  let(:new_stage) { create(:pipeline_stage, pipeline: pipeline) }
  let(:won_stage) { create(:pipeline_stage, pipeline: pipeline) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/pipelines/#{pipeline.id}/items" }

  before do
    account.enable_features!('pipeline')
    create(:inbox_member, user: agent, inbox: inbox)
  end

  describe 'POST /api/v1/accounts/{account.id}/pipelines/:pipeline_id/items' do
    it 'adds a conversation the agent can see to a stage' do
      post base_url, params: { conversation_id: conversation.display_id, pipeline_stage_id: new_stage.id },
                     headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['conversation']['id']).to eq(conversation.display_id)
      expect(new_stage.items.pluck(:conversation_id)).to eq([conversation.id])
    end

    it 'rejects a conversation the agent cannot see' do
      hidden = create(:conversation, account: account)

      post base_url, params: { conversation_id: hidden.display_id, pipeline_stage_id: new_stage.id },
                     headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a stage from another pipeline' do
      other_stage = create(:pipeline_stage, pipeline: create(:pipeline, account: account))

      post base_url, params: { conversation_id: conversation.display_id, pipeline_stage_id: other_stage.id },
                     headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/pipelines/:pipeline_id/items/:id' do
    it 'moves the card to another stage' do
      item = create(:pipeline_item, stage: new_stage, conversation: conversation)

      patch "#{base_url}/#{item.id}", params: { pipeline_stage_id: won_stage.id, position: 0 },
                                      headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(item.reload.pipeline_stage_id).to eq(won_stage.id)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/pipelines/:pipeline_id/items/:id' do
    it 'removes the card from the pipeline' do
      item = create(:pipeline_item, stage: new_stage, conversation: conversation)

      delete "#{base_url}/#{item.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(PipelineItem.exists?(item.id)).to be(false)
    end
  end
end
