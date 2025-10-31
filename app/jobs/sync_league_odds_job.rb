# SyncLeagueOddsJob - Sync odds for a specific league
#
# Fetches events, teams, bookmakers, and lines for one league
# Frequency: 3x daily (morning, afternoon, evening)

class SyncLeagueOddsJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff for transient failures
  retry_on OddsApiClient::RateLimitError, wait: :exponentially_longer, attempts: 5
  retry_on Faraday::Error, wait: 5.seconds, attempts: 3

  def perform(league_key)
    Rails.logger.info "📊 Starting odds sync for #{league_key}..."

    league = League.find_by(key: league_key)
    unless league
      Rails.logger.error "League not found: #{league_key}"
      return
    end

    ingester = OddsDataIngester.new
    result = ingester.sync_sport_odds(league_key)

    Rails.logger.info "✅ Odds sync complete for #{league.name}: " \
                      "#{result[:events_created]} new events, " \
                      "#{result[:events_updated]} updated events, " \
                      "#{result[:lines_created]} new lines"

    result
  rescue => e
    Rails.logger.error "❌ Odds sync failed for #{league_key}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise to trigger retry
  end
end

