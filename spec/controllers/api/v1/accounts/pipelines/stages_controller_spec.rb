require 'rails_helper'

RSpec.describe 'Pipeline Stages API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:pipeline, account: account) }
  let!(:stages) { create_list(:pipeline_stage, 3, pipeline: pipeline) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/pipelines/#{pipeline.id}/stages" }

  before { account.enable_features!('pipeline') }

  it 'adds a stage at the end of the pipeline' do
    post base_url, params: { stage: { name: 'Perdido', color: '#ff0000' } }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['payload']).to include('name' => 'Perdido', 'color' => '#ff0000', 'position' => 3)
  end

  it 'renames and moves a stage' do
    patch "#{base_url}/#{stages.last.id}", params: { stage: { name: 'Primeiro', position: 0 } },
                                           headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(pipeline.stages.reload.pick(:name)).to eq('Primeiro')
    expect(pipeline.stages.pluck(:position)).to eq([0, 1, 2])
  end

  it 'deletes a stage and renumbers the rest' do
    delete "#{base_url}/#{stages.first.id}", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(pipeline.stages.reload.map { |stage| [stage.id, stage.position] }).to eq([[stages[1].id, 0], [stages[2].id, 1]])
  end

  it 'does not let agents change stages' do
    post base_url, params: { stage: { name: 'Perdido' } }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
