class PipelinePolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    index?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  # Moving conversations through the stages is day-to-day agent work; shaping the stages is not.
  def manage_items?
    index?
  end
end
