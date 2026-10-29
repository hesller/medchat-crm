# The waiting list is sold per plan: a superadmin turns it on for each account.
module WaitlistEnabledGuard
  extend ActiveSupport::Concern

  included do
    before_action :ensure_waitlist_enabled
  end

  private

  def ensure_waitlist_enabled
    return if Current.account.waitlist_enabled

    render json: { error: I18n.t('waitlist.disabled') }, status: :forbidden
  end
end
