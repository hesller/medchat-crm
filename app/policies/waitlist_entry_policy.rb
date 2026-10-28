class WaitlistEntryPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  alias show? index?
  alias create? index?
  alias destroy? index?
  alias next? index?
  alias offer? index?
  alias accept? index?
  alias decline? index?
end
