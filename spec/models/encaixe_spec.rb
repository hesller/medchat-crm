# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Encaixe do
  let(:account) { create(:account) }
  let(:professional) { create(:professional, account: account, encaixe_daily_limit: 1, encaixe_calendar_id: '42') }
  let(:contact) { create(:contact, account: account) }
  let(:starts_at) { 1.day.from_now.change(hour: 12, min: 30) }

  describe '.book!' do
    let(:webhook_url) { 'https://n8n.test/webhook/encaixe' }

    around { |example| with_modified_env(ENCAIXE_WEBHOOK_URL: webhook_url) { example.run } }

    before do
      stub_request(:post, webhook_url).to_return(status: 200, body: { uid: 'cal-123' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'books while under the daily limit and keeps the calendar booking uid' do
      encaixe = described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at)

      expect(encaixe).to be_scheduled
      expect(encaixe.external_booking_uid).to eq('cal-123')
    end

    it 'gives the vaga back when the calendar refuses the time' do
      stub_request(:post, webhook_url).to_return(status: 409, body: { error: 'unavailable' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect do
        described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at)
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(professional.encaixes.scheduled.count).to eq(0)
    end

    it 'refuses a professional without an encaixe calendar' do
      professional.update!(encaixe_calendar_id: nil)

      expect do
        described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'refuses once the day is full' do
      create(:encaixe, account: account, professional: professional, starts_at: starts_at, external_booking_uid: 'x')

      expect do
        described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at + 1.hour)
      end.to raise_error(ActiveRecord::RecordInvalid, /limit/i)
    end

    it 'refuses when the professional has no limit set' do
      professional.update!(encaixe_daily_limit: nil)

      expect do
        described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'counts each day separately' do
      create(:encaixe, account: account, professional: professional, starts_at: starts_at, external_booking_uid: 'x')

      expect(described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at + 1.day)).to be_persisted
    end

    it 'frees the slot when an encaixe is cancelled' do
      create(:encaixe, account: account, professional: professional, starts_at: starts_at).cancelled!

      expect(described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at)).to be_persisted
    end
  end
end
