# OddsDataIngester - High-level orchestration for data ingestion
#
# Coordinates fetching data from The Odds API and populating the database
# Handles the full dependency chain: Sport → League → Team → Event → Line

class OddsDataIngester
  attr_reader :client

  def initialize(client: nil)
    @client = client || OddsApiClient.new
    @stats = {
      sports_created: 0,
      leagues_created: 0,
      teams_created: 0,
      events_created: 0,
      events_updated: 0,
      lines_created: 0,
      lines_updated: 0,
      bookmakers_created: 0
    }
  end

  # Sync all sports and leagues from The Odds API
  # This is the initial seeding operation
  def sync_all_sports
    Rails.logger.info "🌱 Syncing sports and leagues from The Odds API..."

    sports_data = @client.fetch_sports(all: false) # Only active sports

    sports_data.each do |sport_data|
      upsert_league(sport_data)
    end

    Rails.logger.info "✅ Sports sync complete: #{@stats[:sports_created]} sports, #{@stats[:leagues_created]} leagues"
    @stats
  end

  # Sync odds for a specific sport/league
  # This fetches events, teams, bookmakers, and lines
  def sync_sport_odds(sport_key)
    Rails.logger.info "📊 Syncing odds for #{sport_key}..."

    league = League.find_by(key: sport_key)
    unless league
      Rails.logger.error "League not found: #{sport_key}"
      return
    end

    odds_data = @client.fetch_odds(
      sport_key,
      regions: ['us'],
      markets: ['h2h', 'spreads', 'totals'],
      odds_format: 'american'
    )

    odds_data.each do |event_data|
      ActiveRecord::Base.transaction do
        event = upsert_event(league: league, api_event_data: event_data)
        upsert_lines(event: event, api_event_data: event_data)
      end
    end

    Rails.logger.info "✅ Odds sync complete for #{sport_key}: #{@stats[:events_created]} new events, #{@stats[:lines_created]} new lines"
    @stats
  end

  # Sync scores for a specific sport/league
  # Updates results for completed events
  def sync_sport_scores(sport_key, days_from: 3)
    Rails.logger.info "🏆 Syncing scores for #{sport_key}..."

    league = League.find_by(key: sport_key)
    unless league
      Rails.logger.error "League not found: #{sport_key}"
      return
    end

    scores_data = @client.fetch_scores(sport_key, days_from: days_from)

    scores_data.each do |score_data|
      next unless score_data['completed']

      event = Event.find_by(odds_api_id: score_data['id'])
      next unless event

      upsert_result(event: event, api_score_data: score_data)
    end

    Rails.logger.info "✅ Scores sync complete for #{sport_key}"
    @stats
  end

  private

  # Upsert Sport and League from API data
  def upsert_league(api_sport_data)
    # API provides: key, group, title, description, active, has_outrights
    sport = Sport.find_or_create_by!(name: api_sport_data['group']) do |s|
      s.description = "#{api_sport_data['group']} sports"
      s.active = true
      @stats[:sports_created] += 1
    end

    league = League.find_or_initialize_by(key: api_sport_data['key'])

    if league.new_record?
      @stats[:leagues_created] += 1
    end

    league.assign_attributes(
      sport: sport,
      name: api_sport_data['title'],
      region: 'us', # The Odds API is US-focused
      active: api_sport_data['active'],
      has_outrights: api_sport_data['has_outrights']
    )

    league.save!
    league
  end

  # Upsert Team using TeamNormalizer
  def upsert_team(league:, team_name:)
    team = TeamNormalizer.find_or_create_team(
      league: league,
      name: team_name
    )

    if team.previously_new_record?
      @stats[:teams_created] += 1
      Rails.logger.info "  ✨ New team: #{team.name} (#{team.normalized_name})"
    end

    team
  end

  # Upsert Bookmaker
  def upsert_bookmaker(bookmaker_key:, bookmaker_title:)
    bookmaker = Bookmaker.find_or_initialize_by(key: bookmaker_key)

    if bookmaker.new_record?
      @stats[:bookmakers_created] += 1
      Rails.logger.info "  ✨ New bookmaker: #{bookmaker_title}"
    end

    bookmaker.assign_attributes(
      name: bookmaker_title,
      region: 'us',
      active: true
    )

    bookmaker.save!
    bookmaker
  end

  # Upsert Event with teams
  def upsert_event(league:, api_event_data:)
    # API provides: id, sport_key, commence_time, home_team, away_team, bookmakers
    home_team = upsert_team(league: league, team_name: api_event_data['home_team'])
    away_team = upsert_team(league: league, team_name: api_event_data['away_team'])

    event = Event.find_or_initialize_by(odds_api_id: api_event_data['id'])

    if event.new_record?
      @stats[:events_created] += 1
    else
      @stats[:events_updated] += 1
    end

    event.assign_attributes(
      league: league,
      home_team: home_team,
      away_team: away_team,
      home_team_name: api_event_data['home_team'],
      away_team_name: api_event_data['away_team'],
      commence_time: Time.parse(api_event_data['commence_time']),
      status: determine_status(api_event_data),
      completed: false,
      last_sync_at: Time.current
    )

    event.save!
    event
  end

  # Upsert Lines for an event (flattened odds structure)
  def upsert_lines(event:, api_event_data:)
    return unless api_event_data['bookmakers'].present?

    api_event_data['bookmakers'].each do |bookmaker_data|
      bookmaker = upsert_bookmaker(
        bookmaker_key: bookmaker_data['key'],
        bookmaker_title: bookmaker_data['title']
      )

      # Flatten all markets into one Line record
      odds_data = flatten_odds_to_line(
        event: event,
        markets_data: bookmaker_data['markets']
      )

      line = Line.find_or_initialize_by(
        event: event,
        bookmaker: bookmaker
      )

      if line.new_record?
        @stats[:lines_created] += 1
      else
        @stats[:lines_updated] += 1
      end

      line.assign_attributes(odds_data)
      line.last_updated = Time.parse(bookmaker_data['last_update']) if bookmaker_data['last_update']
      line.save!
    end
  end

  # Upsert Result for completed event
  def upsert_result(event:, api_score_data:)
    return unless api_score_data['scores'].present?

    scores = api_score_data['scores']
    home_score_data = scores.find { |s| s['name'] == event.home_team_name }
    away_score_data = scores.find { |s| s['name'] == event.away_team_name }

    result = Result.find_or_initialize_by(event: event)
    result.assign_attributes(
      home_score: home_score_data&.dig('score'),
      away_score: away_score_data&.dig('score'),
      final: api_score_data['completed']
    )
    result.save!

    # Mark event as completed
    event.update!(completed: true, status: 'completed')
  end

  # Flatten markets into a single Line record
  def flatten_odds_to_line(event:, markets_data:)
    h2h_market = markets_data.find { |m| m['key'] == 'h2h' }
    spreads_market = markets_data.find { |m| m['key'] == 'spreads' }
    totals_market = markets_data.find { |m| m['key'] == 'totals' }

    {
      # Moneyline (h2h)
      money_line_home: extract_price(h2h_market, event.home_team_name),
      money_line_away: extract_price(h2h_market, event.away_team_name),
      draw_line: extract_price(h2h_market, 'Draw'),

      # Spreads
      point_spread_home: extract_point(spreads_market, event.home_team_name),
      point_spread_away: extract_point(spreads_market, event.away_team_name),
      point_spread_home_line: extract_price(spreads_market, event.home_team_name),
      point_spread_away_line: extract_price(spreads_market, event.away_team_name),

      # Totals
      total_number: extract_point(totals_market, 'Over') || extract_point(totals_market, 'Under'),
      over_line: extract_price(totals_market, 'Over'),
      under_line: extract_price(totals_market, 'Under'),

      source: 'the-odds-api'
    }
  end

  # Extract price (odds) for a specific outcome
  def extract_price(market, outcome_name)
    return nil unless market && market['outcomes']

    outcome = market['outcomes'].find { |o| o['name'] == outcome_name }
    outcome&.dig('price')
  end

  # Extract point (spread/total) for a specific outcome
  def extract_point(market, outcome_name)
    return nil unless market && market['outcomes']

    outcome = market['outcomes'].find { |o| o['name'] == outcome_name }
    outcome&.dig('point')
  end

  # Determine event status based on commence time
  def determine_status(api_event_data)
    commence_time = Time.parse(api_event_data['commence_time'])

    if commence_time > Time.current
      'scheduled'
    elsif commence_time <= Time.current && commence_time > 3.hours.ago
      'live'
    else
      'scheduled' # Default to scheduled if unclear
    end
  end
end

