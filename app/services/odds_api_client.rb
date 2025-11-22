# OddsApiClient - Low-level HTTP client for The Odds API
#
# Handles all API communication, rate limiting, retries, and quota tracking
# Documentation: https://the-odds-api.com/liveapi/guides/v4/

class OddsApiClient
  class RateLimitError < StandardError; end
  class ApiError < StandardError; end

  attr_reader :api_key, :base_url

  def initialize(api_key: nil, base_url: nil)
    @api_key = api_key || OddsApi.configuration.api_key
    @base_url = base_url || OddsApi.configuration.base_url
    @connection = build_connection
  end

  # Fetch list of sports/leagues
  # Free endpoint - doesn't count against quota
  def fetch_sports(all: false)
    params = { apiKey: @api_key }
    params[:all] = true if all

    response = with_retry do
      @connection.get("#{@base_url}/sports", params)
    end

    log_api_usage(response, endpoint: "GET /sports")
    JSON.parse(response.body)
  end

  # Fetch odds for a specific sport
  def fetch_odds(sport_key, regions: ['us'], markets: ['h2h', 'spreads', 'totals'], odds_format: 'american')
    params = {
      apiKey: @api_key,
      regions: regions.join(','),
      markets: markets.join(','),
      oddsFormat: odds_format
    }

    response = with_retry do
      @connection.get("#{@base_url}/sports/#{sport_key}/odds", params)
    end

    log_api_usage(response, endpoint: "GET /sports/#{sport_key}/odds", league_key: sport_key)
    
    # Track usage in database
    track_usage(sport_key)
    
    JSON.parse(response.body)
  end

  # Fetch scores for a specific sport
  def fetch_scores(sport_key, days_from: 3)
    params = {
      apiKey: @api_key,
      daysFrom: days_from
    }

    response = with_retry do
      @connection.get("#{@base_url}/sports/#{sport_key}/scores", params)
    end

    log_api_usage(response, endpoint: "GET /sports/#{sport_key}/scores", league_key: sport_key)
    
    # Track usage in database
    track_usage(sport_key)
    
    JSON.parse(response.body)
  end

  # Fetch upcoming events for a specific sport
  def fetch_events(sport_key, date_format: 'iso', odds_format: 'american')
    params = {
      apiKey: @api_key,
      dateFormat: date_format,
      oddsFormat: odds_format
    }

    response = with_retry do
      @connection.get("#{@base_url}/sports/#{sport_key}/events", params)
    end

    log_api_usage(response, endpoint: "GET /sports/#{sport_key}/events")
    JSON.parse(response.body)
  end

  private

  def build_connection
    Faraday.new do |f|
      f.request :retry, {
        max: 3,
        interval: 0.5,
        backoff_factor: 2,
        exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
      }
      f.adapter Faraday.default_adapter
    end
  end

  def with_retry(max_retries: 3, &block)
    retries = 0
    begin
      response = block.call
      handle_response(response)
      response
    rescue RateLimitError => e
      retries += 1
      if retries < max_retries
        wait_time = 2**retries
        Rails.logger.warn "Rate limited. Waiting #{wait_time}s before retry #{retries}/#{max_retries}"
        sleep(wait_time)
        retry
      else
        Rails.logger.error "Rate limit exceeded after #{max_retries} retries"
        raise
      end
    end
  end

  def handle_response(response)
    case response.status
    when 200..299
      # Success
    when 429
      raise RateLimitError, "API rate limit exceeded"
    when 400..499
      raise ApiError, "Client error: #{response.status} - #{response.body}"
    when 500..599
      raise ApiError, "Server error: #{response.status} - #{response.body}"
    else
      raise ApiError, "Unexpected response: #{response.status}"
    end
  end

  def log_api_usage(response, endpoint:, league_key: nil)
    used = response.headers['x-requests-used']
    remaining = response.headers['x-requests-remaining']
    last = response.headers['x-requests-last']

    Rails.logger.info "API Usage - #{endpoint}: Used=#{used}, Remaining=#{remaining}, Cost=#{last}"

    if remaining && remaining.to_i < 1000
      Rails.logger.warn "⚠️  API quota running low: #{remaining} requests remaining"
    end
  end

  # Track API usage in database for monitoring
  def track_usage(league_key)
    ApiUsageLog.increment_for(league_key)
  rescue => e
    # Don't let tracking errors break API calls
    Rails.logger.error "Failed to track API usage: #{e.message}"
  end
end

