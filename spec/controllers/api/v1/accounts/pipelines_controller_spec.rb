require 'rails_helper'

RSpec.describe 'Pipelines API', type: :request do
  let(:account) { create(:account, pipeline_enabled: true) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/pipelines" }

  describe 'when the pipeline is disabled for the account' do
    let(:account) { create(:account) }

    it 'returns forbidden' do
      get base_url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'blocks the nested endpoints too' do
      pipeline = create(:pipeline, account: account)
      stage = create(:pipeline_stage, pipeline: pipeline)

      post "#{base_url}/#{pipeline.id}/cards", params: { card: { title: 'Deal', pipeline_stage_id: stage.id } },
                                               headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(PipelineCard.count).to eq(0)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/pipelines' do
    it 'returns unauthorized for unauthenticated users' do
      get base_url

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists the account pipelines with their stages for agents' do
      pipeline = create(:pipeline, account: account)
      create(:pipeline_stage, pipeline: pipeline, name: 'Lead')
      create(:pipeline, account: create(:account))

      get base_url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      payload = response.parsed_body['payload']
      expect(payload.pluck('id')).to eq([pipeline.id])
      expect(payload.first['stages'].pluck('name')).to eq(['Lead'])
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/pipelines/:id' do
    it 'returns the board with the cards of each stage in order' do
      pipeline = create(:pipeline, account: account)
      lead = create(:pipeline_stage, pipeline: pipeline)
      won = create(:pipeline_stage, pipeline: pipeline)
      contact = create(:contact, account: account)
      first = create(:pipeline_card, pipeline_stage: lead, contact: contact, assignee: agent, value: 150.5)
      second = create(:pipeline_card, pipeline_stage: lead)

      get "#{base_url}/#{pipeline.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      stages = response.parsed_body['payload']['stages']
      expect(stages.pluck('id')).to eq([lead.id, won.id])
      expect(stages.first['cards'].pluck('id')).to eq([first.id, second.id])
      expect(stages.first['cards'].first).to include(
        'value' => 150.5,
        'contact' => include('id' => contact.id, 'name' => contact.name),
        'assignee' => include('id' => agent.id)
      )
      expect(stages.second['cards']).to eq([])
    end

    it 'does not show a pipeline from another account' do
      other = create(:pipeline, account: create(:account))

      get "#{base_url}/#{other.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/pipelines' do
    let(:params) do
      { pipeline: { name: 'Sales', stages_attributes: [{ name: 'Lead', color: '#FF0000' }, { name: 'Proposal' }, { name: 'Won' }] } }
    end

    it 'creates the pipeline with its stages in the order sent' do
      post base_url, params: params, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      pipeline = account.pipelines.last
      expect(pipeline.name).to eq('Sales')
      expect(pipeline.stages.map(&:name)).to eq(%w[Lead Proposal Won])
      expect(pipeline.stages.map(&:account_id).uniq).to eq([account.id])
      expect(pipeline.stages.first.color).to eq('#FF0000')
    end

    it 'does not let agents create pipelines' do
      post base_url, params: params, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(Pipeline.count).to eq(0)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/pipelines/:id' do
    it 'renames the pipeline' do
      pipeline = create(:pipeline, account: account)

      patch "#{base_url}/#{pipeline.id}", params: { pipeline: { name: 'Renamed' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(pipeline.reload.name).to eq('Renamed')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/pipelines/:id' do
    it 'deletes the pipeline with its stages and cards' do
      pipeline = create(:pipeline, account: account)
      create(:pipeline_card, pipeline_stage: create(:pipeline_stage, pipeline: pipeline))

      delete "#{base_url}/#{pipeline.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect([Pipeline.count, PipelineStage.count, PipelineCard.count]).to eq([0, 0, 0])
    end
  end
end
