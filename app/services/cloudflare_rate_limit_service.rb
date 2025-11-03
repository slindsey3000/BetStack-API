# CloudflareRateLimitService - Shared rate limiting using Cloudflare KV
# Ensures Cloudflare Worker and Rails API share the same rate limit counter

class CloudflareRateLimitService
  RATE_LIMIT_MAX = 1_000 # 1,000 requests per day
  RATE_LIMIT_TTL = 86_400 # 24 hours in seconds

  def initialize(api_key)
    @api_key = api_key
    @rate_limit_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_KV_NAMESPACE_ID'])
  end

  # Check and increment rate limit
  # Returns { allowed: boolean, remaining: integer, reset_at: Time }
  def check_and_increment
    return error_response("API key is required") unless @api_key.present?

    date_key = today_date_key
    current_count = get_current_count(date_key)
    
    # Check if limit exceeded
    if current_count >= RATE_LIMIT_MAX
      return {
        allowed: false,
        remaining: 0,
        reset_at: next_reset_time
      }
    end

    # Increment counter
    new_count = @rate_limit_client.increment(date_key, by: 1, expiration_ttl: RATE_LIMIT_TTL)
    
    if new_count.nil?
      # If increment failed, try to get current count
      new_count = get_current_count(date_key) + 1
      # Attempt to set it
      @rate_limit_client.put(date_key, new_count.to_s)
      new_count = get_current_count(date_key)
    end

    remaining = [RATE_LIMIT_MAX - new_count, 0].max
    
    {
      allowed: true,
      remaining: remaining,
      reset_at: next_reset_time,
      current: new_count
    }
  end

  # Get current count without incrementing
  def current_status
    return error_response("API key is required") unless @api_key.present?

    date_key = today_date_key
    current_count = get_current_count(date_key)
    remaining = [RATE_LIMIT_MAX - current_count, 0].max

    {
      allowed: current_count < RATE_LIMIT_MAX,
      remaining: remaining,
      reset_at: next_reset_time,
      current: current_count
    }
  end

  private

  def today_date_key
    "ratelimit:#{@api_key}:#{Date.current.strftime('%Y-%m-%d')}"
  end

  def get_current_count(key)
    value = @rate_limit_client.get(key)
    value ? value.to_i : 0
  end

  def next_reset_time
    Time.current.end_of_day + 1.second
  end

  def error_response(message)
    {
      allowed: false,
      remaining: 0,
      reset_at: nil,
      error: message
    }
  end
end
