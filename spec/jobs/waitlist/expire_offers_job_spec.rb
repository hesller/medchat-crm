require 'rails_helper'

RSpec.describe Waitlist::ExpireOffersJob do
  let(:account) { create(:account) }
  let(:professional) { create(:professional, account: account) }

  it 'gives expired offers back to the queue and keeps live ones' do
    expired = create(:waitlist_entry, account: account)
    expired.offer!(professional, 2.days.from_now)
    live = create(:waitlist_entry, account: account)
    live.offer!(professional, 3.days.from_now)
    expired.update!(offer_expires_at: 1.minute.ago)

    described_class.perform_now

    expect(expired.reload).to be_waiting
    expect(live.reload).to be_offered
  end

  it 'expires entries that outlived their validity' do
    stale = create(:waitlist_entry, account: account)
    stale.update!(expires_at: 1.day.ago)

    described_class.perform_now

    expect(stale.reload).to be_expired
  end
end
