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
end

