class Waitlist::ExpireOffersJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    WaitlistEntry.offered.where(offer_expires_at: ...Time.current).find_each(&:release_offer!)
    WaitlistEntry.waiting.where(expires_at: ...Time.current).find_each(&:expired!)
  end
end
