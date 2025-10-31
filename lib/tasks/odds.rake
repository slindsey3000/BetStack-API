namespace :odds do
  desc "Test connection to The Odds API"
  task test: :environment do
    puts "🔌 Testing connection to The Odds API..."
    puts ""

    begin
      client = OddsApiClient.new
      sports = client.fetch_sports

      puts "✅ Connection successful!"
      puts ""
      puts "📊 API Status:"
      puts "   - Sports available: #{sports.length}"
      puts "   - Active sports: #{sports.count { |s| s['active'] }}"
      puts ""
      puts "Sample sports:"
      sports.select { |s| s['active'] }.first(5).each do |sport|
        puts "   • #{sport['title']} (#{sport['key']})"
      end
    rescue => e
      puts "❌ Connection failed: #{e.message}"
      puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
      exit 1
    end
  end

  desc "Seed initial data from The Odds API (sports, leagues, teams)"
  task seed: :environment do
    puts "🌱 Seeding BetStack database from The Odds API..."
    puts "=" * 60
    puts ""

    # Step 1: Sync sports and leagues
    puts "Step 1: Fetching sports and leagues..."
    ingester = OddsDataIngester.new
    result = ingester.sync_all_sports

    puts "  ✅ Created #{result[:sports_created]} sports"
    puts "  ✅ Created #{result[:leagues_created]} leagues"
    puts ""

    # Step 2: Fetch odds for active leagues to discover teams
    puts "Step 2: Fetching odds to discover teams and bookmakers..."
    puts ""

    active_leagues = League.active.limit(10) # Start with first 10 leagues
    active_leagues.each_with_index do |league, index|
      puts "  [#{index + 1}/#{active_leagues.count}] #{league.name} (#{league.key})"

      begin
        result = ingester.sync_sport_odds(league.key)
        puts "      ✓ Teams: #{result[:teams_created]} new"
        puts "      ✓ Events: #{result[:events_created]} new"
        puts "      ✓ Lines: #{result[:lines_created]} new"
        puts ""
      rescue => e
        puts "      ✗ Error: #{e.message}"
        puts ""
      end
    end

    # Final stats
    puts "=" * 60
    puts "🎉 Seeding complete!"
    puts ""
    puts "Database Summary:"
    puts "  • Sports: #{Sport.count}"
    puts "  • Leagues: #{League.count} (#{League.active.count} active)"
    puts "  • Teams: #{Team.count}"
    puts "  • Events: #{Event.count} (#{Event.upcoming.count} upcoming)"
    puts "  • Bookmakers: #{Bookmaker.count}"
    puts "  • Lines: #{Line.count}"
    puts ""
  end

  desc "Sync odds for all active leagues"
  task sync: :environment do
    puts "🔄 Syncing odds for all active leagues..."
    puts ""

    ingester = OddsDataIngester.new
    leagues = League.active

    puts "Found #{leagues.count} active leagues"
    puts ""

    leagues.each_with_index do |league, index|
      puts "[#{index + 1}/#{leagues.count}] #{league.name} (#{league.key})"

      begin
        result = ingester.sync_sport_odds(league.key)
        puts "  ✓ Events: #{result[:events_created]} new, #{result[:events_updated]} updated"
        puts "  ✓ Lines: #{result[:lines_created]} new, #{result[:lines_updated]} updated"
      rescue => e
        puts "  ✗ Error: #{e.message}"
      end

      puts ""

      # Small delay to respect rate limits
      sleep(0.5) unless Rails.env.test?
    end

    puts "✅ Sync complete!"
  end

  desc "Sync odds for a specific league"
  task :sync_league, [:league_key] => :environment do |t, args|
    league_key = args[:league_key]

    unless league_key
      puts "❌ Error: Please provide a league key"
      puts "Usage: rails odds:sync_league[americanfootball_nfl]"
      exit 1
    end

    league = League.find_by(key: league_key)
    unless league
      puts "❌ Error: League not found: #{league_key}"
      puts ""
      puts "Available leagues:"
      League.active.pluck(:name, :key).each do |name, key|
        puts "  • #{name} (#{key})"
      end
      exit 1
    end

    puts "🔄 Syncing odds for #{league.name} (#{league_key})..."
    puts ""

    ingester = OddsDataIngester.new
    result = ingester.sync_sport_odds(league_key)

    puts "✅ Sync complete!"
    puts "  • Teams: #{result[:teams_created]} new"
    puts "  • Events: #{result[:events_created]} new, #{result[:events_updated]} updated"
    puts "  • Lines: #{result[:lines_created]} new, #{result[:lines_updated]} updated"
    puts "  • Bookmakers: #{result[:bookmakers_created]} new"
  end

  desc "Sync scores for completed events"
  task :sync_scores, [:league_key] => :environment do |t, args|
    league_key = args[:league_key]

    if league_key
      # Sync specific league
      puts "🏆 Syncing scores for #{league_key}..."
      ingester = OddsDataIngester.new
      ingester.sync_sport_scores(league_key)
    else
      # Sync all active leagues
      puts "🏆 Syncing scores for all active leagues..."
      puts ""

      ingester = OddsDataIngester.new
      League.active.each do |league|
        puts "  • #{league.name}"
        ingester.sync_sport_scores(league.key)
      end
    end

    puts ""
    puts "✅ Scores sync complete!"
  end

  desc "Show database statistics"
  task stats: :environment do
    puts "📊 BetStack Database Statistics"
    puts "=" * 60
    puts ""

    puts "Stable Entities:"
    puts "  • Sports: #{Sport.count} (#{Sport.active.count} active)"
    puts "  • Leagues: #{League.count} (#{League.active.count} active)"
    puts "  • Teams: #{Team.count} (#{Team.active.count} active)"
    puts "  • Bookmakers: #{Bookmaker.count} (#{Bookmaker.active.count} active)"
    puts ""

    puts "Dynamic Entities:"
    puts "  • Events: #{Event.count}"
    puts "    - Upcoming: #{Event.upcoming.count}"
    puts "    - Live: #{Event.live.count}"
    puts "    - Completed: #{Event.completed.count}"
    puts "  • Lines: #{Line.count}"
    puts "  • Results: #{Result.count}"
    puts ""

    puts "Top Leagues by Event Count:"
    League.joins(:events).group('leagues.name').count.sort_by { |k, v| -v }.first(10).each do |name, count|
      puts "  • #{name}: #{count} events"
    end
    puts ""

    puts "Last Sync:"
    last_sync = Event.order(last_sync_at: :desc).first&.last_sync_at
    if last_sync
      puts "  #{last_sync.strftime('%B %d, %Y at %I:%M %p')}"
    else
      puts "  Never"
    end
  end

  desc "Clean up old completed events (older than 30 days)"
  task :cleanup, [:days] => :environment do |t, args|
    days = (args[:days] || 30).to_i
    cutoff_date = days.days.ago

    puts "🧹 Cleaning up events older than #{days} days (before #{cutoff_date.strftime('%B %d, %Y')})..."
    puts ""

    old_events = Event.where('completed = ? AND commence_time < ?', true, cutoff_date)
    count = old_events.count

    if count == 0
      puts "No old events to clean up."
    else
      puts "Found #{count} old completed events"
      print "Are you sure you want to delete these? (y/N): "
      response = STDIN.gets.chomp.downcase

      if response == 'y'
        old_events.destroy_all
        puts "✅ Deleted #{count} old events"
      else
        puts "Cancelled"
      end
    end
  end
end

