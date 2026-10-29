# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Encaixe do
  let(:account) { create(:account) }
  let(:professional) { create(:professional, account: account, encaixe_daily_limit: 1) }
  let(:contact) { create(:contact, account: account) }
  let(:starts_at) { 1.day.from_now.change(hour: 12, min: 30) }

  describe '.book!' do
    it 'books while under the daily limit' do
      expect(described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at)).to be_persisted
    end

    it 'refuses once the day is full' do
      create(:encaixe, account: account, professional: professional, starts_at: starts_at)

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
      create(:encaixe, account: account, professional: professional, starts_at: starts_at)

      expect(described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at + 1.day)).to be_persisted
    end

    it 'frees the slot when an encaixe is cancelled' do
      create(:encaixe, account: account, professional: professional, starts_at: starts_at).cancelled!

      expect(described_class.book!(account: account, professional: professional, contact: contact, starts_at: starts_at)).to be_persisted
    end
  end
end
