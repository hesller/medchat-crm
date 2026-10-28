require 'rails_helper'

RSpec.describe 'Waitlist entries API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:professional) { create(:professional, account: account, specialty: 'Cardiologia') }
  let(:contact) { create(:contact, account: account) }
  let(:slot) { 2.days.from_now.change(usec: 0).iso8601 }
  let(:path) { "/api/v1/accounts/#{account.id}/waitlist_entries" }

  describe 'GET /waitlist_entries' do
    it 'returns unauthorized for an unauthenticated user' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists only the entries of the account, oldest first, filtered by status' do
      first = create(:waitlist_entry, account: account)
      second = create(:waitlist_entry, account: account)
      create(:waitlist_entry, account: account, status: :cancelled)
      create(:waitlist_entry)

      get path, params: { status: 'waiting' }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].pluck('id')).to eq([first.id, second.id])
    end
  end

  describe 'POST /waitlist_entries' do
    it 'queues a patient for a professional' do
      post path, params: { waitlist_entry: { contact_id: contact.id, professional_id: professional.id } },
                 headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('status' => 'waiting', 'specialty' => 'Cardiologia')
    end

    it 'rejects a contact from another account' do
      post path, params: { waitlist_entry: { contact_id: create(:contact).id, specialty: 'Cardiologia' } },
                 headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects the same patient queued twice for the same request' do
      create(:waitlist_entry, account: account, contact: contact, specialty: 'Cardiologia')

      post path, params: { waitlist_entry: { contact_id: contact.id, specialty: 'Cardiologia' } },
                 headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /waitlist_entries/next' do
    it 'returns the oldest patient waiting for the professional or the specialty' do
      oldest = create(:waitlist_entry, account: account, specialty: 'Cardiologia')
      create(:waitlist_entry, account: account, professional: professional)

      get "#{path}/next", params: { professional_id: professional.id }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['id']).to eq(oldest.id)
    end

    it 'skips the patient who already declined that slot' do
      decliner = create(:waitlist_entry, account: account)
      decliner.offer!(professional, Time.zone.parse(slot))
      decliner.release_offer!
      next_in_line = create(:waitlist_entry, account: account)

      get "#{path}/next", params: { professional_id: professional.id, slot_starts_at: slot },
                          headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['id']).to eq(next_in_line.id)
    end

    it 'returns no content when nobody is waiting' do
      get "#{path}/next", params: { professional_id: professional.id }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'offer, accept and decline' do
    let!(:entry) { create(:waitlist_entry, account: account) }

    it 'offers a slot and exposes the offer' do
      post "#{path}/#{entry.id}/offer", params: { professional_id: professional.id, slot_starts_at: slot },
                                        headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['offer']).to include('slot_starts_at')
      expect(entry.reload).to be_offered
    end

    it 'returns unprocessable entity for an unparseable slot' do
      post "#{path}/#{entry.id}/offer", params: { professional_id: professional.id, slot_starts_at: '2026-13-45' },
                                        headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'schedules an accepted offer' do
      entry.offer!(professional, Time.zone.parse(slot))

      post "#{path}/#{entry.id}/accept", headers: agent.create_new_auth_token, as: :json

      expect(entry.reload).to be_scheduled
    end

    it 'puts a declined offer back in the queue' do
      entry.offer!(professional, Time.zone.parse(slot))

      post "#{path}/#{entry.id}/decline", headers: agent.create_new_auth_token, as: :json

      expect(entry.reload).to be_waiting
    end
  end

  describe 'DELETE /waitlist_entries/:id' do
    it 'cancels the entry and keeps the record' do
      entry = create(:waitlist_entry, account: account)

      delete "#{path}/#{entry.id}", headers: agent.create_new_auth_token, as: :json

      expect(entry.reload).to be_cancelled
    end
  end
end
