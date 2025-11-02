# Console Helpers for BetStack API
# Usage: These methods are available in Rails console (rails c)

module BetStackConsoleHelpers
  # Get lines for a specific league
  # Example: lines_for("americanfootball_nfl")
  def lines_for(league_key, bookmaker_key: nil)
    scope = Line.joins(event: :league).where(leagues: { key: league_key })
    scope = scope.joins(:bookmaker).where(bookmakers: { key: bookmaker_key }) if bookmaker_key
    
    lines = scope.includes(event: [:home_team, :away_team, :league], bookmaker: [])
    
    puts "📊 Found #{lines.count} lines for #{League.find_by(key: league_key)&.name || league_key}"
    puts ""
    
    lines.each do |line|
      event = line.event
      puts "🏈 #{event.home_team.name} vs #{event.away_team.name}"
      puts "   Bookmaker: #{line.bookmaker.name}"
      puts "   Commence: #{event.commence_time.strftime('%Y-%m-%d %I:%M %p')}"
      
      if line.moneyline
        puts "   Moneyline: #{line.moneyline['home']} / #{line.moneyline['away']}"
      end
      
      if line.spread
        puts "   Spread: #{line.spread['home']['point']} (#{line.spread['home']['price']}) / #{line.spread['away']['point']} (#{line.spread['away']['price']})"
      end
      
      if line.total
        puts "   Total: #{line.total['number']} (Over: #{line.total['over']}, Under: #{line.total['under']})"
      end
      
      puts ""
    end
    
    lines
  end

  # Quick shortcuts for NFL and NBA
  def nfl_lines(bookmaker_key: nil)
    lines_for("americanfootball_nfl", bookmaker_key: bookmaker_key)
  end

  def nba_lines(bookmaker_key: nil)
    lines_for("basketball_nba", bookmaker_key: bookmaker_key)
  end

  def nhl_lines(bookmaker_key: nil)
    lines_for("icehockey_nhl", bookmaker_key: bookmaker_key)
  end

  def mlb_lines(bookmaker_key: nil)
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
end

# Include helpers in Rails console
if defined?(Rails::Console)
  Rails.application.console do
    include BetStackConsoleHelpers
  end
end

