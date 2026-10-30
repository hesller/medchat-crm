require 'rails_helper'

RSpec.describe 'Health Plans API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:nacional) { create(:health_plan, account: account, name: 'Unimed Nacional') }

  describe 'GET /api/v1/accounts/{account.id}/health_plans' do
    it 'returns unauthorized for an unauthenticated user' do
      get "/api/v1/accounts/#{account.id}/health_plans"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lets an agent search the plans of the account by part of the name' do
      create(:health_plan, account: account, name: 'Unimed Regional')
      create(:health_plan, account: account, name: 'Amil 500')
      create(:health_plan, name: 'Unimed Outra Conta')

      get "/api/v1/accounts/#{account.id}/health_plans", params: { q: 'unimed' }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].pluck('name')).to eq(['Unimed Nacional', 'Unimed Regional'])
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/health_plans' do
    it 'creates a plan for an administrator' do
      expect do
        post "/api/v1/accounts/#{account.id}/health_plans", params: { health_plan: { name: 'Amil 500' } },
                                                            headers: admin.create_new_auth_token, as: :json
      end.to change(account.health_plans, :count).by(1)
    end

    it 'does not let an agent create a plan' do
      post "/api/v1/accounts/#{account.id}/health_plans", params: { health_plan: { name: 'Amil 500' } },
                                                          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unprocessable entity for a duplicate name' do
      post "/api/v1/accounts/#{account.id}/health_plans", params: { health_plan: { name: 'unimed nacional' } },
                                                          headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/health_plans/{id}' do
    it 'removes the plan and its links to professionals' do
      professional = create(:professional, account: account, health_plans: [nacional])

      delete "/api/v1/accounts/#{account.id}/health_plans/#{nacional.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(professional.reload.health_plans).to be_empty
    end
  end
end
