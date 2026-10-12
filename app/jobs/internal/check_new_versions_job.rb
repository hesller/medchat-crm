class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Rails.env.production?

    latest_version = fetch_latest_github_release
    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, latest_version) if latest_version.present?
  end

  private

  # This fork versions itself (4.0.1, 4.0.2, ...), so the version it is compared against has to
  # come from its own releases. Comparing against upstream's would keep the update banner on for
  # every administrator, pointing at releases that are not ours.
  def release_repository
    ENV.fetch('VERSION_CHECK_REPO', 'hesller/medchat-crm')
  end

  def fetch_latest_github_release
    # `max_retries: 0` alongside the ceiling: `Net::HTTP` repeats an idempotent request
    # once by default, so 5 seconds was 10 against a GitHub that accepts and stalls.
    response = HTTParty.get("https://api.github.com/repos/#{release_repository}/releases/latest", timeout: 5, max_retries: 0)
    unless response.success?
      Rails.logger.error "Failed to fetch latest GitHub release: HTTP #{response.code} - #{response.body}"
      return nil
    end

    response['tag_name']&.sub(/^v/, '')
  rescue StandardError => e
    Rails.logger.error "Failed to fetch latest GitHub release: #{e.message}"
    nil
  end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
