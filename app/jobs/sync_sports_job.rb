# SyncSportsJob - Sync sports and leagues from The Odds API
#
# This job should run once daily to update the list of available sports and leagues
# Frequency: Daily (sports and leagues rarely change)

class SyncSportsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🌱 Starting sports sync job..."

    ingester = OddsDataIngester.new
    result = ingester.sync_all_sports

    Rails.logger.info "✅ Sports sync complete: #{result[:sports_created]} sports, #{result[:leagues_created]} leagues"

    result
  rescue => e
    Rails.logger.error "❌ Sports sync failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise to trigger retry
  end
end

