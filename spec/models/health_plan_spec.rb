require 'rails_helper'

RSpec.describe HealthPlan do
  let(:account) { create(:account) }

  it 'rejects a duplicate name in the same account regardless of case' do
    create(:health_plan, account: account, name: 'Unimed Nacional')

    duplicate = build(:health_plan, account: account, name: 'unimed nacional')

    expect(duplicate).not_to be_valid
  end

  it 'allows the same name in another account' do
    create(:health_plan, account: account, name: 'Unimed Nacional')

    expect(build(:health_plan, name: 'Unimed Nacional')).to be_valid
  end

  it 'finds plans by part of the name, ignoring case' do
    nacional = create(:health_plan, account: account, name: 'Unimed Nacional')
    regional = create(:health_plan, account: account, name: 'Unimed Regional')
    create(:health_plan, account: account, name: 'Amil 500')

    expect(account.health_plans.name_matching('unimed')).to contain_exactly(nacional, regional)
  end
end
