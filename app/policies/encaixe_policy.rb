class EncaixePolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  alias create? index?
  alias destroy? index?
end
