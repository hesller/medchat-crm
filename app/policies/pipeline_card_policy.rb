class PipelineCardPolicy < ApplicationPolicy
  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  def move?
    create?
  end
end
