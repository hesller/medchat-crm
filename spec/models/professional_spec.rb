require 'rails_helper'

RSpec.describe Professional do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:specialty) }

    it 'does not allow the same calendar id twice in one account' do
      account = create(:account)
      create(:professional, account: account, external_calendar_id: 'abc')

      duplicate = build(:professional, account: account, external_calendar_id: 'abc')

      expect(duplicate).not_to be_valid
    end

    it 'allows the same calendar id in different accounts' do
      create(:professional, external_calendar_id: 'abc')

      expect(build(:professional, external_calendar_id: 'abc')).to be_valid
    end

    it 'allows many professionals without a calendar id' do
      account = create(:account)
      create(:professional, account: account)

      expect(build(:professional, account: account)).to be_valid
    end
  end
end
