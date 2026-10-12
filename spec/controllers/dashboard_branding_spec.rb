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

    it 'serves the account brand on the login page of the account host' do
      account.update!(brand_host: 'clinica.example.com')

      host! 'clinica.example.com'
      get '/app/login'

      expect(response.body).to include 'Clinica Exemplo'
      expect(response.body).to include "/manifest.json?account_id=#{account.id}"
    end

    it 'keeps the installation brand on the login page of any other host' do
      account.update!(brand_host: 'clinica.example.com')

      host! 'outra.example.com'
      get '/app/login'

      expect(response.body).not_to include 'Clinica Exemplo'
    end

    it 'lets the account in the path win over the host' do
      other = create(:account)
      other.enable_features!('branded_dashboard')
      other.update!(brand_name: 'Outra Clinica', brand_host: 'outra.example.com')

      host! 'outra.example.com'
      get "/app/accounts/#{account.id}/dashboard"

      expect(response.body).to include 'Clinica Exemplo'
      expect(response.body).not_to include 'Outra Clinica'
    end

    context 'with a logo uploaded' do
      before do
        account.brand_logo_email.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end

      it 'uses the account logo as the favicon instead of the Chatwoot files' do
        install('DISPLAY_MANIFEST' => true)

        get "/app/accounts/#{account.id}/dashboard"

        expect(response.body).to include '/rails/active_storage/blobs/'
        expect(response.body).not_to include '/favicon-32x32.png'
        expect(response.body).not_to include '/favicon-16x16.png'
      end
    end

    it 'keeps the Chatwoot favicons while the account has no logo' do
      install('DISPLAY_MANIFEST' => true)

      get "/app/accounts/#{account.id}/dashboard"

      expect(response.body).to include '/favicon-32x32.png'
    end

    it 'ignores an account id that does not exist' do
      get '/app/accounts/999999/dashboard'

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include 'Clinica Exemplo'
    end
  end
end
