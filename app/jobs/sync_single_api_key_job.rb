# SyncSingleApiKeyJob - Immediately syncs a single API key to Cloudflare KV
# Called when a new user is created to ensure instant API access

class SyncSingleApiKeyJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    return unless cloudflare_configured?

    user = User.find_by(id: user_id)
    return unless user&.valid_key?

    Rails.logger.info "🔑 Syncing API key for user #{user.email} to Cloudflare KV..."

    api_keys_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_API_KEYS_NAMESPACE_ID'])
    
    # Store the API key with status and email for usage tracking
    key_data = { status: 'valid', email: user.email }.to_json
    api_keys_client.write(user.api_key, key_data)

    Rails.logger.info "✅ API key synced for #{user.email}"
  rescue => e
    Rails.logger.error "❌ Failed to sync API key for user #{user_id}: #{e.message}"
  end

  private

  def cloudflare_configured?
    required_vars = [
      'CLOUDFLARE_ACCOUNT_ID',
      'CLOUDFLARE_API_KEYS_NAMESPACE_ID',
      'CLOUDFLARE_API_TOKEN'
    ]

    required_vars.all? { |var| ENV[var].present? }
  end
end

