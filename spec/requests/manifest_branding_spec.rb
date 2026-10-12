# frozen_string_literal: true

require 'rails_helper'

describe 'GET /manifest.json', type: :request do
  let(:account) { create(:account) }

  def install(values)
    values.each { |name, value| InstallationConfig.where(name: name).first_or_initialize.update!(value: value) }
    GlobalConfig.clear_cache
  end

  before { install('INSTALLATION_NAME' => 'Chatwoot', 'BRAND_COLOR' => '#1F93FF') }

  it 'serves the installation manifest by default' do
    get '/manifest.json'

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['name']).to eq 'Chatwoot'
    expect(response.parsed_body['theme_color']).to eq '#1F93FF'
  end

  it 'ignores account_id when the account has not enabled the branded dashboard' do
    account.update!(brand_name: 'Clinica Exemplo')

    get '/manifest.json', params: { account_id: account.id }

    expect(response.parsed_body['name']).to eq 'Chatwoot'
  end

  it 'serves the account brand when the account has enabled the branded dashboard' do
    account.enable_features!('branded_dashboard')
    account.update!(brand_name: 'Clinica Exemplo', brand_color: '#0F766E')

    get '/manifest.json', params: { account_id: account.id }

    expect(response.parsed_body['name']).to eq 'Clinica Exemplo'
    expect(response.parsed_body['short_name']).to eq 'Clinica Exemplo'
    expect(response.parsed_body['theme_color']).to eq '#0F766E'
  end

  it 'ignores a non-numeric or unknown account_id' do
    get '/manifest.json', params: { account_id: 'abc' }
    expect(response.parsed_body['name']).to eq 'Chatwoot'

    get '/manifest.json', params: { account_id: 999_999 }
    expect(response.parsed_body['name']).to eq 'Chatwoot'
  end
end
