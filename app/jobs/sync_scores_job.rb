# SyncScoresJob - Sync scores for completed events
#
# Updates Result records for events that have finished
# Frequency: Hourly or as needed

class SyncScoresJob < ApplicationJob
  queue_as :default

  retry_on Faraday::Error, wait: 5.seconds, attempts: 3

  def perform(league_key = nil)
    if league_key
      sync_league_scores(league_key)
    else
      sync_all_scores
    end
  end

  private

  def sync_league_scores(league_key)
    Rails.logger.info "🏆 Starting scores sync for #{league_key}..."

    league = League.find_by(key: league_key)
    unless league
      Rails.logger.error "League not found: #{league_key}"
      return
    end

    ingester = OddsDataIngester.new
    ingester.sync_sport_scores(league_key)

    Rails.logger.info "✅ Scores sync complete for #{league.name}"
  rescue => e
    Rails.logger.error "❌ Scores sync failed for #{league_key}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def sync_all_scores
    Rails.logger.info "🏆 Starting scores sync for major North American leagues..."

    major_leagues = League.major_north_american.to_a
    Rails.logger.info "Found #{major_leagues.count} major leagues: #{major_leagues.map(&:name).join(', ')}"

    major_leagues.each do |league|
      sync_league_scores(league.key)
    end

    Rails.logger.info "✅ All scores synced"
  end
end

