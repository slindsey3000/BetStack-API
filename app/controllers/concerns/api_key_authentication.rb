# ApiKeyAuthentication - Validates API keys from X-API-Key header
# Checks both database and Cloudflare KV for consistency

module ApiKeyAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_key!
  end

  private

  def authenticate_api_key!
    api_key = extract_api_key
    
    unless api_key.present?
      render_unauthorized("API key is required. Please provide X-API-Key header.")
      return
    end

    # Validate against database
    @current_user = User.find_by(api_key: api_key)
    
    unless @current_user&.valid_key?
      render_unauthorized("Invalid or expired API key.")
      return
    end

    # Optional: Verify in Cloudflare KV for consistency (if available)
    if cloudflare_configured?
      kv_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_API_KEYS_NAMESPACE_ID'])
      kv_value = kv_client.get(api_key)
      
      # KV sync might be delayed, so this is just a warning, not a failure
      unless kv_value == 'valid'
        Rails.logger.warn "API key #{api_key[0..8]}... not found in Cloudflare KV (sync may be pending)"
      end
    end
  end

  def extract_api_key
    request.headers['X-API-Key'] || request.headers['HTTP_X_API_KEY']
  end

  def current_user
    @current_user
  end

  def render_unauthorized(message)
    render json: {
      error: "Unauthorized",
      message: message
    }, status: :unauthorized
  end

  def cloudflare_configured?
    ENV['CLOUDFLARE_API_KEYS_NAMESPACE_ID'].present? &&
    ENV['CLOUDFLARE_API_TOKEN'].present? &&
    ENV['CLOUDFLARE_ACCOUNT_ID'].present?
  end
end
