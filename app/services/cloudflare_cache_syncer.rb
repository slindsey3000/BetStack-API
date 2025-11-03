# CloudflareCacheSyncer - Syncs API endpoint responses to Cloudflare KV
# Runs every minute to ensure edge cache is fresh

class CloudflareCacheSyncer
  def initialize
    @cache_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_KV_NAMESPACE_ID'])
    @api_keys_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_API_KEYS_NAMESPACE_ID'])
  end

  # Sync all cacheable endpoints to Cloudflare KV
  def sync_all_endpoints
    start_time = Time.current
    
    endpoints = build_endpoint_list
    bulk_data = []

    endpoints.each do |endpoint|
      begin
        response = generate_endpoint_response(endpoint)
        cache_key = "cache:#{endpoint}"
        bulk_data << [cache_key, response.to_json]
      rescue => e
        Rails.logger.error "Failed to generate response for #{endpoint}: #{e.message}"
      end
    end

    success = @cache_client.bulk_put(bulk_data)
    
    duration = Time.current - start_time
    Rails.logger.info "Synced #{bulk_data.count} endpoints to Cloudflare KV in #{duration.round(2)}s"
    
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

