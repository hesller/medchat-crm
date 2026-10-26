require 'rails_helper'

RSpec.describe 'Pipeline stages API', type: :request do
  let(:account) { create(:account, pipeline_enabled: true) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:pipeline, account: account) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/pipelines/#{pipeline.id}/stages" }

  describe 'POST /stages' do
    it 'appends the stage to the end of the pipeline' do
      existing = create(:pipeline_stage, pipeline: pipeline)

      post base_url, params: { stage: { name: 'Won', color: '#00AA00' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(pipeline.stages.reload.map(&:id).first).to eq(existing.id)
      expect(pipeline.stages.last).to have_attributes(name: 'Won', color: '#00AA00', account_id: account.id)
    end

    it 'rejects an invalid color' do
      post base_url, params: { stage: { name: 'Won', color: 'green' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not let agents manage stages' do
      post base_url, params: { stage: { name: 'Won' } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /stages/reorder' do
    let!(:stages) { create_list(:pipeline_stage, 3, pipeline: pipeline) }

    it 'stores the new order' do
      ids = [stages[2].id, stages[0].id, stages[1].id]

      patch "#{base_url}/reorder", params: { ids: ids }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('id')).to eq(ids)
      expect(pipeline.stages.reload.map(&:id)).to eq(ids)
    end

    it 'rejects a list that is not exactly the stages of the pipeline' do
      foreign = create(:pipeline_stage)

      patch "#{base_url}/reorder", params: { ids: [stages[0].id, stages[1].id, foreign.id] }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(foreign.reload.position).to eq(1)
    end
  end

  describe 'DELETE /stages/:id' do
    it 'deletes the stage and its cards' do
      stage = create(:pipeline_stage, pipeline: pipeline)
      create(:pipeline_card, pipeline_stage: stage)

      delete "#{base_url}/#{stage.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect([PipelineStage.count, PipelineCard.count]).to eq([0, 0])
    end
  end
end
