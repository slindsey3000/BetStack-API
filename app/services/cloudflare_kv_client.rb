# CloudflareKvClient - Service for interacting with Cloudflare KV storage
# Handles pushing data to Cloudflare edge locations

class CloudflareKvClient
  def initialize(namespace_id: nil)
    @account_id = ENV['CLOUDFLARE_ACCOUNT_ID']
    @namespace_id = namespace_id || ENV['CLOUDFLARE_KV_NAMESPACE_ID']
    @api_token = ENV['CLOUDFLARE_API_TOKEN']
    @base_url = "https://api.cloudflare.com/client/v4/accounts/#{@account_id}/storage/kv/namespaces/#{@namespace_id}"
  end

  # Put a single key-value pair
  def put(key, value)
    conn = Faraday.new do |f|
      f.adapter Faraday.default_adapter
    end

    response = conn.put("#{@base_url}/values/#{key}") do |req|
      req.headers['Authorization'] = "Bearer #{@api_token}"
      req.headers['Content-Type'] = 'text/plain'
      req.body = value
    end

    if response.success?
      Rails.logger.debug "✓ Cloudflare KV: Stored #{key}"
      true
    else
      Rails.logger.error "✗ Cloudflare KV: Failed to store #{key} - #{response.status}: #{response.body}"
      false
    end
  end

  # Put multiple key-value pairs in bulk (more efficient)
  def bulk_put(key_value_pairs)
    conn = Faraday.new do |f|
      f.request :json
      f.adapter Faraday.default_adapter
    end

    body = key_value_pairs.map { |k, v| { key: k, value: v } }

    response = conn.put("#{@base_url}/bulk") do |req|
      req.headers['Authorization'] = "Bearer #{@api_token}"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    if response.success?
      Rails.logger.info "✓ Cloudflare KV: Bulk stored #{key_value_pairs.count} keys"
      true
    else
      Rails.logger.error "✗ Cloudflare KV: Bulk storage failed - #{response.status}: #{response.body}"
      false
    end
  end

  # Get a value by key
  def get(key)
    conn = Faraday.new do |f|
      f.adapter Faraday.default_adapter
    end

    response = conn.get("#{@base_url}/values/#{key}") do |req|
      req.headers['Authorization'] = "Bearer #{@api_token}"
    end

    if response.success?
      response.body
    else
      nil
    end
  end

  # Increment a numeric value atomically (GET + PUT pattern)
  # Note: Cloudflare KV REST API doesn't support atomic increment with TTL
  # We use GET + PUT pattern which has a small race condition window
  # TTL is set by Cloudflare Worker when it first creates the key
  # Returns the new value after increment, or nil on failure
  def increment(key, by: 1, expiration_ttl: nil)
    # Get current value
    current_value = get(key)
    current_count = current_value ? current_value.to_i : 0
    
    # Increment
    new_count = current_count + by
    
    # Put new value
    # Note: expiration_ttl parameter is accepted but not used via REST API
    # TTL must be set via Workers KV API or metadata API
    success = put(key, new_count.to_s)
    return new_count if success
    
    nil
  end

  # Delete a key
  def delete(key)
    conn = Faraday.new do |f|
      f.adapter Faraday.default_adapter
    end

    response = conn.delete("#{@base_url}/values/#{key}") do |req|
      req.headers['Authorization'] = "Bearer #{@api_token}"
    end

    response.success?
  end

  # List keys with optional prefix filter
  # Returns array of key names
  # Note: KV list API returns up to 1000 keys per request
  def list_keys(prefix: nil, limit: 1000)
    conn = Faraday.new do |f|
      f.adapter Faraday.default_adapter
    end

    params = { limit: limit }
    params[:prefix] = prefix if prefix.present?

    response = conn.get("#{@base_url}/keys") do |req|
      req.headers['Authorization'] = "Bearer #{@api_token}"
      req.params = params
    end

    if response.success?
      result = JSON.parse(response.body)
      # Returns array of { name: "key_name", ... } objects
      result['result']&.map { |k| k['name'] } || []
    else
      Rails.logger.error "Cloudflare KV list_keys failed: #{response.status} - #{response.body}"
      []
    end
  end

  # Bulk delete keys
  def bulk_delete(keys)
    return true if keys.empty?
    
    conn = Faraday.new do |f|
      f.request :json
      f.adapter Faraday.default_adapter
    end

    response = conn.delete("#{@base_url}/bulk") do |req|
      req.headers['Authorization'] = "Bearer #{@api_token}"
      req.headers['Content-Type'] = 'application/json'
      req.body = keys.to_json
    end

    if response.success?
      Rails.logger.info "Cloudflare KV: Bulk deleted #{keys.count} keys"
      true
    else
      Rails.logger.error "Cloudflare KV bulk delete failed: #{response.status} - #{response.body}"
      false
    end
  end
end

