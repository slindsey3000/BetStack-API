# SyncAllOddsJob - Orchestrator job that syncs odds for all active leagues
#
# Creates individual SyncLeagueOddsJob for each active league
# Frequency: 3x daily (morning, afternoon, evening)

class SyncAllOddsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🔄 Starting sync for all active leagues..."

    active_leagues = League.active.to_a
    Rails.logger.info "Found #{active_leagues.count} active leagues"

    active_leagues.each do |league|
      # Queue individual job for each league
      # This allows parallel processing and independent retries
      SyncLeagueOddsJob.perform_later(league.key)
    end

    Rails.logger.info "✅ Queued #{active_leagues.count} league sync jobs"

    { leagues_queued: active_leagues.count }
  rescue => e
    Rails.logger.error "❌ Failed to queue league sync jobs: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end

