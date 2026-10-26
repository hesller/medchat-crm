require 'rails_helper'

RSpec.describe 'Pipelines API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:pipeline, account: account) }

  before { account.enable_features!('pipeline') }

  describe 'GET /api/v1/accounts/{account.id}/pipelines' do
    it 'returns forbidden when the account does not have the pipeline feature' do
      account.disable_features!('pipeline')

      get "/api/v1/accounts/#{account.id}/pipelines", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists the pipelines of the account' do
      pipeline

      get "/api/v1/accounts/#{account.id}/pipelines", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('name')).to eq([pipeline.name])
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/pipelines/:id' do
    let(:inbox) { create(:inbox, account: account) }
    let(:stage) { create(:pipeline_stage, pipeline: pipeline) }
    let!(:visible_item) { create(:pipeline_item, stage: stage, conversation: create(:conversation, account: account, inbox: inbox)) }
    let!(:hidden_item) { create(:pipeline_item, stage: stage) }

    before { create(:inbox_member, user: agent, inbox: inbox) }

    it 'returns the stages with only the cards the agent can see' do
      get "/api/v1/accounts/#{account.id}/pipelines/#{pipeline.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      stage_payload = response.parsed_body['payload']['stages'].first
      expect(stage_payload['items'].pluck('id')).to eq([visible_item.id])
      expect(stage_payload['items'].first['conversation']['id']).to eq(visible_item.conversation.display_id)
    end

    it 'returns every card to an administrator' do
      get "/api/v1/accounts/#{account.id}/pipelines/#{pipeline.id}", headers: admin.create_new_auth_token, as: :json

      expect(response.parsed_body['payload']['stages'].first['items'].pluck('id')).to eq([visible_item.id, hidden_item.id])
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/pipelines' do
    let(:params) { { pipeline: { name: 'Vendas' }, stage_names: %w[Novo Ganho] } }

    it 'creates a pipeline with its stages' do
      post "/api/v1/accounts/#{account.id}/pipelines", params: params, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['stages'].pluck('name', 'position')).to eq([['Novo', 0], ['Ganho', 1]])
    end

    it 'does not let agents create pipelines' do
      post "/api/v1/accounts/#{account.id}/pipelines", params: params, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/pipelines/:id' do
    it 'removes the pipeline with its stages and cards' do
      create(:pipeline_item, stage: create(:pipeline_stage, pipeline: pipeline))

      delete "/api/v1/accounts/#{account.id}/pipelines/#{pipeline.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect([Pipeline.count, PipelineStage.count, PipelineItem.count]).to eq([0, 0, 0])
    end
  end
end
