# RateLimitable - Enforces 1,000 requests/day limit per API key
# Uses Cloudflare KV for shared rate limiting with edge Worker

module RateLimitable
  extend ActiveSupport::Concern

  included do
    before_action :check_rate_limit!, if: -> { current_user.present? }
  end

  private

  def check_rate_limit!
    api_key = extract_api_key
    return unless api_key.present?

    rate_limit_service = CloudflareRateLimitService.new(api_key)
    result = rate_limit_service.check_and_increment

    unless result[:allowed]
      render_rate_limit_exceeded(result)
      return
    end

    # Add rate limit headers to response
    add_rate_limit_headers(result)
  end

  def extract_api_key
    request.headers['X-API-Key'] || request.headers['HTTP_X_API_KEY']
  end

  def render_rate_limit_exceeded(result)
    headers = rate_limit_headers(result)
    
    render json: {
      error: "Rate limit exceeded",
      message: "Maximum 1,000 requests per day. Limit resets at #{result[:reset_at]&.iso8601}",
      limit: 1_000,
      reset_at: result[:reset_at]&.iso8601
    }, status: :too_many_requests, headers: headers
  end

  def add_rate_limit_headers(result)
    headers = rate_limit_headers(result)
    headers.each { |k, v| response.headers[k] = v }
  end

  def rate_limit_headers(result)
    {
      'X-RateLimit-Limit' => '1000',
      'X-RateLimit-Remaining' => result[:remaining].to_s,
      'X-RateLimit-Reset' => result[:reset_at]&.to_i.to_s
    }
  end
end
