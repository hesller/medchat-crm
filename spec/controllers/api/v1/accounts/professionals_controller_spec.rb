require 'rails_helper'

RSpec.describe 'Professionals API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:cardiologist) { create(:professional, account: account, name: 'Dr. Carlos', specialty: 'Cardiologia') }
  let!(:inactive_dermatologist) { create(:professional, account: account, name: 'Dra. Ana', specialty: 'Dermatologia', active: false) }

  describe 'GET /api/v1/accounts/{account.id}/professionals' do
    it 'returns unauthorized for an unauthenticated user' do
      get "/api/v1/accounts/#{account.id}/professionals"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lets an agent list the professionals of the account only' do
      create(:professional, name: 'Dr. Outra Conta')

      get "/api/v1/accounts/#{account.id}/professionals", headers: agent.create_new_auth_token, as: :json

      names = response.parsed_body['payload'].pluck('name')
      expect(names).to contain_exactly('Dr. Carlos', 'Dra. Ana')
    end

    it 'filters by active and specialty' do
      get "/api/v1/accounts/#{account.id}/professionals",
          params: { active: 'true', specialty: 'Cardiologia' },
          headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].pluck('name')).to eq(['Dr. Carlos'])
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/professionals' do
    let(:valid_params) { { professional: { name: 'Dr. Novo', specialty: 'Ortopedia', external_calendar_id: 'cal-9' } } }

    it 'creates a professional for an administrator' do
      expect do
        post "/api/v1/accounts/#{account.id}/professionals", params: valid_params, headers: admin.create_new_auth_token, as: :json
      end.to change(account.professionals, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['external_calendar_id']).to eq('cal-9')
    end

    it 'does not let an agent create a professional' do
      expect do
        post "/api/v1/accounts/#{account.id}/professionals", params: valid_params, headers: agent.create_new_auth_token, as: :json
      end.not_to change(Professional, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unprocessable entity without a specialty' do
      post "/api/v1/accounts/#{account.id}/professionals",
           params: { professional: { name: 'Dr. Sem Especialidade' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/professionals/:id' do
    it 'updates the professional for an administrator' do
      patch "/api/v1/accounts/#{account.id}/professionals/#{cardiologist.id}",
            params: { professional: { active: false } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(cardiologist.reload.active).to be(false)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/professionals/:id' do
    it 'deletes the professional for an administrator' do
      expect do
        delete "/api/v1/accounts/#{account.id}/professionals/#{cardiologist.id}", headers: admin.create_new_auth_token, as: :json
      end.to change(account.professionals, :count).by(-1)
    end

    it 'does not let an agent delete a professional' do
      delete "/api/v1/accounts/#{account.id}/professionals/#{cardiologist.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
