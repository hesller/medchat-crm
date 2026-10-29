require 'rails_helper'

RSpec.describe WaitlistEntry do
  let(:account) { create(:account) }
  let(:professional) { create(:professional, account: account, specialty: 'Cardiologia') }
  let(:slot) { 2.days.from_now.change(usec: 0) }

  describe 'creation' do
    it 'takes the specialty of the requested professional' do
      entry = create(:waitlist_entry, account: account, professional: professional, specialty: nil)

      expect(entry.specialty).to eq('Cardiologia')
    end

    it 'expires after the validity configured on the account' do
      account.update!(waitlist_entry_validity_days: 10)

      entry = create(:waitlist_entry, account: account)

      expect(entry.expires_at).to be_within(1.minute).of(10.days.from_now)
    end

    it 'rejects a second open entry of the same patient for the same request' do
      first = create(:waitlist_entry, account: account)

      duplicate = build(:waitlist_entry, account: account, contact: first.contact)

      expect(duplicate).not_to be_valid
    end

    it 'allows a new entry once the previous one was cancelled' do
      first = create(:waitlist_entry, account: account, status: :cancelled)

      expect(build(:waitlist_entry, account: account, contact: first.contact)).to be_valid
    end

    it 'rejects a professional from another account' do
      entry = build(:waitlist_entry, account: account, professional: create(:professional))

      expect(entry).not_to be_valid
    end
  end

  describe '.matching' do
    it 'finds entries for the professional or for any professional of the specialty' do
      for_professional = create(:waitlist_entry, account: account, professional: professional)
      for_specialty = create(:waitlist_entry, account: account, specialty: 'Cardiologia')
      create(:waitlist_entry, account: account, specialty: 'Dermatologia')
      create(:waitlist_entry, account: account, professional: create(:professional, account: account, specialty: 'Cardiologia'))

      expect(described_class.matching(professional)).to contain_exactly(for_professional, for_specialty)
    end
  end

  describe '#offer!' do
    let(:entry) { create(:waitlist_entry, account: account) }

    it 'holds the slot for the configured number of minutes' do
      account.update!(waitlist_offer_timeout_minutes: 45)

      entry.offer!(professional, slot)

      expect(entry).to be_offered
      expect(entry.offer_expires_at).to be_within(1.minute).of(45.minutes.from_now)
    end

    it 'rejects a slot in the past' do
      expect { entry.offer!(professional, 1.hour.ago) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'rejects a professional of another specialty' do
      other = create(:professional, account: account, specialty: 'Dermatologia')

      expect { entry.offer!(other, slot) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'rejects another professional when the patient asked for a specific one' do
      requested = create(:waitlist_entry, account: account, professional: professional)
      colleague = create(:professional, account: account, specialty: 'Cardiologia')

      expect { requested.offer!(colleague, slot) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'does not offer one slot to two patients' do
      entry.offer!(professional, slot)

      expect { create(:waitlist_entry, account: account).offer!(professional, slot) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'does not offer a slot the patient already declined' do
      entry.offer!(professional, slot)
      entry.release_offer!

      expect { entry.offer!(professional, slot) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'with quiet hours' do
      before { account.update!(reporting_timezone: 'UTC', waitlist_quiet_hours_start: '20:00', waitlist_quiet_hours_end: '08:00') }

      it 'refuses offers during the night' do
        travel_to(Time.utc(2026, 11, 3, 22, 0)) do
          expect { entry.offer!(professional, slot) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'allows offers during the day' do
        travel_to(Time.utc(2026, 11, 3, 12, 0)) do
          expect { entry.offer!(professional, 2.days.from_now) }.not_to raise_error
        end
      end
    end
  end

  describe '#release_offer!' do
    it 'sends the patient back to the queue and clears the offer' do
      entry = create(:waitlist_entry, account: account)
      entry.offer!(professional, slot)

      entry.release_offer!

      expect(entry).to be_waiting
      expect(entry.offered_professional).to be_nil
      expect(entry.offer_expires_at).to be_nil
    end
  end

  describe '#accept!' do
    it 'schedules a live offer' do
      entry = create(:waitlist_entry, account: account)
      entry.offer!(professional, slot)

      entry.accept!

      expect(entry).to be_scheduled
    end

    it 'refuses an offer that already expired' do
      entry = create(:waitlist_entry, account: account)
      entry.offer!(professional, slot)

      travel_to(2.hours.from_now) do
        expect { entry.accept! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
