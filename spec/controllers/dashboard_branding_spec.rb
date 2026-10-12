# frozen_string_literal: true

require 'rails_helper'

describe 'Dashboard branding per account', type: :request do
  let(:account) { create(:account) }

  def install(values)
    values.each { |name, value| InstallationConfig.where(name: name).first_or_initialize.update!(value: value) }
    GlobalConfig.clear_cache
  end

  before { install('INSTALLATION_NAME' => 'Chatwoot', 'BRAND_COLOR' => '#1F93FF') }

  context 'when the account has not enabled the branded dashboard' do
    before { account.update!(brand_name: 'Clinica Exemplo') }

    it 'serves the installation brand' do
      get "/app/accounts/#{account.id}/dashboard"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include 'Clinica Exemplo'
      expect(response.body).to include '<link rel="manifest" href="/manifest.json">'
    end
  end

  context 'when the account has enabled the branded dashboard' do
    before do
      account.enable_features!('branded_dashboard')
      account.update!(brand_name: 'Clinica Exemplo', brand_color: '#0F766E')
    end

    it 'serves the account brand for that account only' do
      get "/app/accounts/#{account.id}/dashboard"

      expect(response.body).to include 'Clinica Exemplo'
      expect(response.body).to include '#0F766E'
      expect(response.body).to include "/manifest.json?account_id=#{account.id}"
    end

    it 'keeps the installation brand on pages with no account in the URL' do
      get '/app/login'

      expect(response.body).not_to include 'Clinica Exemplo'
      expect(response.body).to include '<link rel="manifest" href="/manifest.json">'
    end

    it 'ignores an account id that does not exist' do
      get '/app/accounts/999999/dashboard'

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include 'Clinica Exemplo'
    end
  end
end
