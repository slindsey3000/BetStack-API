# SmartSchedulerJob - Intelligent odds and results sync scheduler
#
# Runs every minute and decides what needs syncing based on:
# - League season status (calendar-based month check)
# - Time until next game (different frequencies for different windows)
# - Active games (live results syncing)
#
# Target: ~17,000 API requests/month
# Frequency tiers:
# - Odds: 30min baseline, 10min within 2hrs, 2min within 10min of game
# - Results: 2min during/after games (within 3 hours)

class SmartSchedulerJob < ApplicationJob
  queue_as :default

  # Odds sync frequency tiers (in seconds)
  ODDS_BASELINE_FREQUENCY = 30.minutes
  ODDS_PRE_GAME_2HR_FREQUENCY = 10.minutes
  ODDS_PRE_GAME_10MIN_FREQUENCY = 2.minutes

  # Results sync frequency (in seconds)
  RESULTS_LIVE_FREQUENCY = 2.minutes

  def perform
    Rails.logger.info "🧠 Smart Scheduler: Evaluating sync needs..."

    stats = {
      leagues_checked: 0,
      odds_syncs_queued: 0,
      results_syncs_queued: 0
    }

    League.major_north_american.each do |league|
      stats[:leagues_checked] += 1

      # Check if league is in season (calendar-based month check)
      unless in_season?(league)
        Rails.logger.debug "  ⏸️  #{league.name}: Out of season, skipping"
        next
      end

      # Sync odds if needed
      if should_sync_odds?(league)
        SyncLeagueOddsJob.perform_later(league.key)
        stats[:odds_syncs_queued] += 1
        Rails.logger.info "  📊 #{league.name}: Queued odds sync"
      end

      # Sync results if needed
      if should_sync_results?(league)
        SyncScoresJob.perform_later(league.key)
        stats[:results_syncs_queued] += 1
        Rails.logger.info "  🏆 #{league.name}: Queued results sync"
      end
    end

    Rails.logger.info "✅ Smart Scheduler complete: " \
                      "#{stats[:odds_syncs_queued]} odds, " \
                      "#{stats[:results_syncs_queued]} results queued"

    stats
  end

  private

  def in_season?(league)
    # Use calendar-based season detection from League model
    league.in_season?
  end

  def should_sync_odds?(league)
    # Determine odds sync frequency based on time until next game
    frequency = determine_odds_frequency(league)
    return false unless frequency

    # Check if enough time has passed since last sync
    league.needs_odds_sync?(frequency)
  end

  def should_sync_results?(league)
    # Check if league has any live or recently completed games
    has_active_games = league.events.live.exists? ||
                       league.events.recently_completed.exists?

    return false unless has_active_games

    # Check if enough time has passed since last results sync
    league.needs_results_sync?(RESULTS_LIVE_FREQUENCY)
  end

  def determine_odds_frequency(league)
    # Get time until next game in this league
    seconds_until_next = Event.time_until_next_game(league.key)

    # No upcoming games
    return nil unless seconds_until_next

    # Determine frequency tier based on time until game
    if seconds_until_next <= 10.minutes
      ODDS_PRE_GAME_10MIN_FREQUENCY  # Every 2 minutes (final approach)
    elsif seconds_until_next <= 2.hours
      ODDS_PRE_GAME_2HR_FREQUENCY    # Every 10 minutes (pre-game)
    else
      ODDS_BASELINE_FREQUENCY        # Every 30 minutes (baseline)
    end
  end
end

