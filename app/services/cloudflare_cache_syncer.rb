# CloudflareCacheSyncer - Syncs API endpoint responses to Cloudflare KV
# Uses timestamp-based change detection to minimize KV writes and Heroku load
# Only syncs when data actually changes (optimized for free tier)

class CloudflareCacheSyncer
  def initialize
    @cache_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_KV_NAMESPACE_ID'])
    @api_keys_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_API_KEYS_NAMESPACE_ID'])
  end

  # Sync all cacheable endpoints to Cloudflare KV (only if data changed)
  def sync_all_endpoints
    start_time = Time.current
    
    endpoints = build_endpoint_list
    bulk_data = []
    checked_count = 0
    changed_count = 0
    
    endpoints.each do |endpoint|
      begin
        checked_count += 1
        
        # Lightweight check: Has data changed since last sync?
        changed, current_timestamp = data_changed_with_timestamp?(endpoint)
        
        if changed
          changed_count += 1
          
          # Only NOW generate full response (expensive operation)
          response = generate_endpoint_response(endpoint)
          cache_key = "cache:#{endpoint}"
          bulk_data << [cache_key, response.to_json]
          
          # Update sync timestamp only when data changed (minimizes KV writes)
          if current_timestamp
            sync_time_key = "sync_time:#{endpoint}"
            bulk_data << [sync_time_key, current_timestamp.iso8601]
          end
          
          Rails.logger.debug "Data changed for #{endpoint} - will sync"
        end
      rescue => e
        Rails.logger.error "Failed to check/sync #{endpoint}: #{e.message}"
      end
    end

    # Write data changes (includes timestamps when data changed)
    if bulk_data.any?
      success = @cache_client.bulk_put(bulk_data)
    else
      success = true
      Rails.logger.debug "No data changes detected - skipping KV writes"
    end
    
    duration = Time.current - start_time
    # bulk_data includes both cache entries and timestamp updates (2x changed_count when changed)
    cache_entries_written = changed_count
    Rails.logger.info "Checked #{checked_count} endpoints, #{changed_count} changed, #{cache_entries_written} cache entries (#{bulk_data.count} KV writes total) in #{duration.round(2)}s"
    
    success
  end

  # Sync valid API keys to Cloudflare KV for edge validation
  def sync_api_keys
    start_time = Time.current
    bulk_data = []

    User.valid.find_each do |user|
      bulk_data << [user.api_key, 'valid']
    end

    success = @api_keys_client.bulk_put(bulk_data) if bulk_data.any?
    
    duration = Time.current - start_time
    Rails.logger.info "Synced #{bulk_data.count} API keys to Cloudflare in #{duration.round(2)}s"
    
    success
  end

  private

  def build_endpoint_list
    endpoints = [
      '/api/v1/sports',
      '/api/v1/leagues',
      '/api/v1/events',
      '/api/v1/lines',
      '/api/v1/lines/incomplete',
      '/api/v1/results',
      '/api/v1/teams',
      '/api/v1/bookmakers'
    ]

    # Add league-specific endpoints for major leagues
    League::MAJOR_NORTH_AMERICAN_LEAGUES.each do |league_key|
      endpoints << "/api/v1/lines?league_key=#{league_key}"
      endpoints << "/api/v1/events?league_key=#{league_key}"
    end

    endpoints
  end

  # Check if data has changed since last sync using timestamp comparison
  # Returns [changed, current_timestamp] - lightweight check
  def data_changed_with_timestamp?(endpoint)
    sync_time_key = "sync_time:#{endpoint}"
    
    # Get current max updated_at timestamp for this endpoint's data
    current_max_timestamp = get_max_updated_at(endpoint)
    
    # Get last sync timestamp from KV (read operation - free!)
    last_sync_str = @cache_client.get(sync_time_key)
    last_sync_timestamp = last_sync_str ? Time.parse(last_sync_str) : nil
    
    # Handle no data case
    if current_max_timestamp.nil?
      # No data exists
      # Sync on first run only (to establish empty cache)
      # If we previously had data (last_sync_timestamp exists), don't sync every time
      # Data might have expired/filtered out, but we'll update when new data arrives
      return [last_sync_timestamp.nil?, Time.current]
    end
    
    # If no previous sync or data is newer, data changed
    changed = last_sync_timestamp.nil? || current_max_timestamp > last_sync_timestamp
    
    [changed, current_max_timestamp]
  end

  # Get maximum updated_at timestamp for endpoint's underlying data
  # Lightweight: Only runs simple MAX queries, no JSON generation
  def get_max_updated_at(endpoint)
    uri = URI.parse("http://localhost#{endpoint}")
    path = uri.path
    params = Rack::Utils.parse_query(uri.query)

    case path
    when '/api/v1/sports'
      Sport.maximum(:updated_at)
      
    when '/api/v1/leagues'
      League.maximum(:updated_at)
      
    when '/api/v1/events'
      scope = Event.where('commence_time > ? OR (commence_time <= ? AND completed = ?)', 
                         Time.current, Time.current, false)
      
      if params['league_key']
        scope = scope.joins(:league).where(leagues: { key: params['league_key'] })
      end
      
      scope.maximum(:updated_at)
      
    when '/api/v1/lines'
      scope = Line.joins(:event)
                  .where('events.commence_time > ? OR (events.commence_time <= ? AND events.completed = ?)',
                         Time.current, Time.current, false)
      
      league_key = params['league_key'].present? ? params['league_key'] : League::MAJOR_NORTH_AMERICAN_LEAGUES
      scope = scope.joins(event: :league).where(leagues: { key: league_key })
      
      bookmaker_key = params['bookmaker_key'] || 'betstack'
      scope = scope.joins(:bookmaker).where(bookmakers: { key: bookmaker_key })
      
      scope.maximum(:updated_at)
      
    when '/api/v1/lines/incomplete'
      scope = Line.incomplete
                  .joins(:event, :bookmaker)
                  .where('events.commence_time > ? OR (events.commence_time <= ? AND events.completed = ?)',
                         Time.current, Time.current, false)
                  .joins(event: :league).where(leagues: { key: League::MAJOR_NORTH_AMERICAN_LEAGUES })
                  .where(bookmakers: { key: 'betstack' })
      
      scope.maximum(:updated_at)
      
    when '/api/v1/results'
      Result.joins(:event)
            .where('events.commence_time > ?', 3.days.ago)
            .maximum(:updated_at)
            
    when '/api/v1/teams'
      Team.maximum(:updated_at)
      
    when '/api/v1/bookmakers'
      Bookmaker.maximum(:updated_at)
      
    else
      nil
    end
  end

  def generate_endpoint_response(endpoint)
    # Parse endpoint and params
    uri = URI.parse("http://localhost#{endpoint}")
    path = uri.path
    params = Rack::Utils.parse_query(uri.query)

    # Route to appropriate controller action and generate response
    case path
    when '/api/v1/sports'
      Sport.order(:name).map(&:api_json)
      
    when '/api/v1/leagues'
      League.order(:name).map(&:api_json)
      
    when '/api/v1/events'
      scope = Event.includes(:league, :home_team, :away_team)
      
      if params['league_key']
        scope = scope.joins(:league).where(leagues: { key: params['league_key'] })
      end
      
      # Only upcoming and live events
      scope = scope.where('commence_time > ? OR (commence_time <= ? AND completed = ?)', 
                         Time.current, Time.current, false)
      scope = scope.order(commence_time: :asc)
      
      scope.map(&:api_json)
      
    when '/api/v1/lines'
      scope = Line.includes(:bookmaker, event: [:league, :home_team, :away_team])
                  .joins(:event)
                  .where('events.commence_time > ? OR (events.commence_time <= ? AND events.completed = ?)',
                         Time.current, Time.current, false)
      
      # Filter by league (default to major North American leagues)
      league_key = params['league_key'].present? ? params['league_key'] : League::MAJOR_NORTH_AMERICAN_LEAGUES
      scope = scope.joins(event: :league).where(leagues: { key: league_key })
      
      # Filter by bookmaker (default to BetStack consensus)
      bookmaker_key = params['bookmaker_key'] || 'betstack'
      scope = scope.joins(:bookmaker).where(bookmakers: { key: bookmaker_key })
      
      scope = scope.order('events.commence_time ASC')
      scope.map(&:api_json)
      
    when '/api/v1/lines/incomplete'
      scope = Line.incomplete
                  .includes(:bookmaker, event: [:league, :home_team, :away_team])
                  .joins(:event, :bookmaker)
                  .where('events.commence_time > ? OR (events.commence_time <= ? AND events.completed = ?)',
                         Time.current, Time.current, false)
      
      # Default to major North American leagues and BetStack
      scope = scope.joins(event: :league).where(leagues: { key: League::MAJOR_NORTH_AMERICAN_LEAGUES })
      scope = scope.where(bookmakers: { key: 'betstack' })
      scope = scope.order('events.commence_time ASC')
      
      scope.map(&:api_json)
      
    when '/api/v1/results'
      Result.includes(event: [:league, :home_team, :away_team])
            .joins(:event)
            .where('events.commence_time > ?', 3.days.ago)
            .order('events.commence_time DESC')
            .map(&:api_json)
            
    when '/api/v1/teams'
      Team.includes(:league).order(:name).map(&:api_json)
      
    when '/api/v1/bookmakers'
      Bookmaker.order(:name).map(&:api_json)
      
    else
      []
    end
  end
end

