# Console Helpers for BetStack API
# Usage: These methods are available in Rails console (rails c)

module BetStackConsoleHelpers
  # Get lines for a specific league
  # Example: lines_for("americanfootball_nfl")
  # Defaults to BetStack consensus lines unless bookmaker_key is specified
  def lines_for(league_key, bookmaker_key: "betstack")
    scope = Line.joins(event: :league).where(leagues: { key: league_key })
    scope = scope.joins(:bookmaker).where(bookmakers: { key: bookmaker_key })
    scope = scope.order("events.commence_time ASC")

    lines = scope.includes(event: [ :home_team, :away_team, :league ], bookmaker: [])

    puts "📊 Found #{lines.count} lines for #{League.find_by(key: league_key)&.name || league_key}"
    puts ""

    lines.each do |line|
      event = line.event
      puts "🏈 #{event.home_team.name} vs #{event.away_team.name}"
      puts "   Bookmaker: #{line.bookmaker.name}"
      puts "   Commence: #{event.commence_time.strftime('%Y-%m-%d %I:%M %p')}"

      if line.has_moneyline?
        puts "   Moneyline: #{line.money_line_home} / #{line.money_line_away}"
      end

      if line.has_spread?
        puts "   Spread: #{line.point_spread_home} (#{line.point_spread_home_line}) / #{line.point_spread_away} (#{line.point_spread_away_line})"
      end

      if line.has_totals?
        puts "   Total: #{line.total_number} (Over: #{line.over_line}, Under: #{line.under_line})"
      end

      puts ""
    end

    lines
  end

  # Quick shortcuts for NFL and NBA
  # Default to BetStack consensus lines unless bookmaker_key is specified
  def nfl_lines(bookmaker_key: "betstack")
    lines_for("americanfootball_nfl", bookmaker_key: bookmaker_key)
  end

  def nba_lines(bookmaker_key: "betstack")
    lines_for("basketball_nba", bookmaker_key: bookmaker_key)
  end

  def nhl_lines(bookmaker_key: "betstack")
    lines_for("icehockey_nhl", bookmaker_key: bookmaker_key)
  end

  def mlb_lines(bookmaker_key: "betstack")
    lines_for("baseball_mlb", bookmaker_key: bookmaker_key)
  end

  # Refresh odds for a league
  # Example: refresh_odds("americanfootball_nfl")
  def refresh_odds(league_key)
    league = League.find_by(key: league_key)

    unless league
      puts "❌ League not found: #{league_key}"
      puts ""
      puts "Available leagues:"
      League.active.pluck(:name, :key).each do |name, key|
        puts "  • #{name} (#{key})"
      end
      return
    end

    puts "🔄 Refreshing odds for #{league.name}..."

    ingester = OddsDataIngester.new
    result = ingester.sync_sport_odds(league_key)

    puts ""
    puts "✅ Refresh complete!"
    puts "  • Events: #{result[:events_created]} new, #{result[:events_updated]} updated"
    puts "  • Lines: #{result[:lines_created]} new, #{result[:lines_updated]} updated"
    puts "  • Teams: #{result[:teams_created]} new" if result[:teams_created] > 0
    puts "  • Bookmakers: #{result[:bookmakers_created]} new" if result[:bookmakers_created] > 0

    result
  end

  # Quick refresh shortcuts
  def refresh_nfl
    refresh_odds("americanfootball_nfl")
  end

  def refresh_nba
    refresh_odds("basketball_nba")
  end

  def refresh_nhl
    refresh_odds("icehockey_nhl")
  end

  def refresh_mlb
    refresh_odds("baseball_mlb")
  end

  # Refresh results/scores for a league
  # Example: refresh_results("americanfootball_nfl")
  def refresh_results(league_key)
    league = League.find_by(key: league_key)

    unless league
      puts "❌ League not found: #{league_key}"
      return
    end

    puts "🏆 Refreshing results for #{league.name}..."

    ingester = OddsDataIngester.new
    ingester.sync_sport_scores(league_key)

    puts "✅ Results refresh complete!"
  end

  # Quick result refresh shortcuts
  def refresh_nfl_results
    refresh_results("americanfootball_nfl")
  end

  def refresh_nba_results
    refresh_results("basketball_nba")
  end

  # Show stats for a league
  def league_stats(league_key)
    league = League.find_by(key: league_key)

    unless league
      puts "❌ League not found: #{league_key}"
      return
    end

    puts "📊 Statistics for #{league.name}"
    puts "=" * 60
    puts ""
    puts "Teams: #{league.teams.count}"
    puts "Events: #{league.events.count}"
    puts "  • Upcoming: #{league.events.upcoming.count}"
    puts "  • Live: #{league.events.live.count}"
    puts "  • Completed: #{league.events.completed.count}"
    puts "Lines: #{Line.joins(event: :league).where(leagues: { key: league_key }).count}"
    puts "Results: #{Result.joins(event: :league).where(leagues: { key: league_key }).count}"
    puts ""

    last_sync = league.events.order(last_sync_at: :desc).first&.last_sync_at
    if last_sync
      puts "Last sync: #{last_sync.strftime('%Y-%m-%d %I:%M %p')}"
    else
      puts "Last sync: Never"
    end
  end

  # Refresh all major leagues
  def refresh_all_odds
    puts "🔄 Refreshing odds for all major North American leagues..."
    puts ""

    ingester = OddsDataIngester.new
    leagues = League.major_north_american

    leagues.each_with_index do |league, index|
      puts "[#{index + 1}/#{leagues.count}] #{league.name}"
      result = ingester.sync_sport_odds(league.key)
      puts "  ✓ Events: #{result[:events_created]} new, #{result[:events_updated]} updated"
      puts "  ✓ Lines: #{result[:lines_created]} new, #{result[:lines_updated]} updated"
      puts ""
      sleep(0.5) unless Rails.env.test?
    end

    puts "✅ All odds refreshed!"
  end

  def refresh_all_results
    puts "🏆 Refreshing results for all major North American leagues..."
    puts ""

    ingester = OddsDataIngester.new
    leagues = League.major_north_american

    leagues.each_with_index do |league, index|
      puts "[#{index + 1}/#{leagues.count}] #{league.name}"
      ingester.sync_sport_scores(league.key)
      puts ""
      sleep(0.5) unless Rails.env.test?
    end

    puts "✅ All results refreshed!"
  end

  # Get lines with missing market data
  # Example: incomplete_lines
  # Example: incomplete_lines("americanfootball_nfl")
  def incomplete_lines(league_key: nil, bookmaker_key: "betstack")
    scope = Line.incomplete
                .joins(event: :league)
                .where("events.commence_time > ? OR (events.commence_time <= ? AND events.completed = ?)",
                       Time.current, Time.current, false)

    if league_key
      scope = scope.where(leagues: { key: league_key })
    else
      scope = scope.where(leagues: { key: League::MAJOR_NORTH_AMERICAN_LEAGUES })
    end

    scope = scope.joins(:bookmaker).where(bookmakers: { key: bookmaker_key })
    scope = scope.order("events.commence_time ASC")

    lines = scope.includes(event: [ :home_team, :away_team, :league ], bookmaker: [])

    puts "⚠️  Found #{lines.count} lines with missing market data"
    puts ""

    if lines.empty?
      puts "✅ All lines are complete!"
      return lines
    end

    lines.each do |line|
      event = line.event
      missing = line.missing_markets

      puts "🏈 #{event.home_team.name} vs #{event.away_team.name}"
      puts "   League: #{event.league.name}"
      puts "   Bookmaker: #{line.bookmaker.name}"
      puts "   Commence: #{event.commence_time.strftime('%Y-%m-%d %I:%M %p')}"
      puts "   ⚠️  Missing: #{missing.join(', ')}"

      if line.has_moneyline? && !line.moneyline_complete?
        puts "      Moneyline: #{line.money_line_home || 'MISSING'} / #{line.money_line_away || 'MISSING'}"
      end

      if line.has_spread? && !line.spread_complete?
        puts "      Spread: #{line.point_spread_home || 'MISSING'} (#{line.point_spread_home_line || 'MISSING'}) / #{line.point_spread_away || 'MISSING'} (#{line.point_spread_away_line || 'MISSING'})"
      end

      if line.has_totals? && !line.totals_complete?
        puts "      Total: #{line.total_number || 'MISSING'} (Over: #{line.over_line || 'MISSING'}, Under: #{line.under_line || 'MISSING'})"
      end

      puts ""
    end

    lines
  end

  # Show all available console commands and rake tasks
  def help
    puts "🎯 BetStack API - Available Commands"
    puts "=" * 70
    puts ""

    puts "📊 GET LINES (Odds)"
    puts "-" * 70
    puts "  nfl_lines              Get NFL betting lines"
    puts "  nba_lines              Get NBA betting lines"
    puts "  nhl_lines              Get NHL betting lines"
    puts "  mlb_lines              Get MLB betting lines"
    puts "  lines_for(league_key)  Get lines for any league"
    puts "  incomplete_lines       Get lines with missing market data"
    puts ""

    puts "🔄 REFRESH ODDS"
    puts "-" * 70
    puts "  refresh_nfl            Refresh NFL odds from API"
    puts "  refresh_nba            Refresh NBA odds from API"
    puts "  refresh_nhl            Refresh NHL odds from API"
    puts "  refresh_mlb            Refresh MLB odds from API"
    puts "  refresh_odds(key)      Refresh odds for any league"
    puts "  refresh_all_odds       Refresh all major leagues"
    puts ""

    puts "🏆 REFRESH RESULTS"
    puts "-" * 70
    puts "  refresh_nfl_results    Refresh NFL scores/results"
    puts "  refresh_nba_results    Refresh NBA scores/results"
    puts "  refresh_results(key)   Refresh results for any league"
    puts "  refresh_all_results    Refresh all major leagues"
    puts ""

    puts "📈 STATISTICS"
    puts "-" * 70
    puts "  league_stats(key)      Show stats for a league"
    puts ""

    puts "🔧 RAKE TASKS"
    puts "-" * 70
    puts "  rails odds:test                    Test API connection"
    puts "  rails odds:seed                    Seed initial data"
    puts "  rails odds:sync                    Sync all major leagues"
    puts "  rails odds:sync_league[key]        Sync specific league"
    puts "  rails odds:sync_scores[key]        Sync scores for league"
    puts "  rails odds:stats                   Show database stats"
    puts ""

    puts "⚙️  BACKGROUND JOBS (Manual - Dev Only)"
    puts "-" * 70
    puts "  SyncAllOddsJob.perform_now         Sync all odds immediately"
    puts "  SyncSportsJob.perform_now          Sync sports/leagues"
    puts "  SyncScoresJob.perform_now          Sync all scores"
    puts "  SyncCloudflareCacheCriticalJob.perform_now  Sync edge cache"
    puts ""

    puts "💡 Examples:"
    puts "-" * 70
    puts "  nfl_lines"
    puts "  refresh_nfl"
    puts "  league_stats('americanfootball_nfl')"
    puts "  SyncAllOddsJob.perform_now"
    puts ""
  end
end

# Include helpers in Rails console and auto-display help on startup
if defined?(Rails::Console)
  Rails.application.console do
    include BetStackConsoleHelpers
    # Automatically show help when console loads
    help
  end
end
