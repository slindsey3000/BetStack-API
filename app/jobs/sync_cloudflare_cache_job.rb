# SyncCloudflareCacheJob - Background job to sync API data to Cloudflare edge
# Runs every minute to keep edge cache fresh

class SyncCloudflareCacheJob < ApplicationJob
  queue_as :default

  def perform
    return unless cloudflare_configured?

    Rails.logger.info "🌐 Starting Cloudflare cache sync..."
    
    syncer = CloudflareCacheSyncer.new
    
    # Sync endpoint responses
    syncer.sync_all_endpoints
    
    # Sync API keys for edge validation
    syncer.sync_api_keys
    
    Rails.logger.info "✅ Cloudflare cache sync complete"
  rescue => e
    Rails.logger.error "❌ Cloudflare cache sync failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def cloudflare_configured?
    required_vars = [
      'CLOUDFLARE_ACCOUNT_ID',
      'CLOUDFLARE_KV_NAMESPACE_ID',
      'CLOUDFLARE_API_KEYS_NAMESPACE_ID',
      'CLOUDFLARE_API_TOKEN'
    ]

    missing = required_vars.reject { |var| ENV[var].present? }
    
    if missing.any?
      Rails.logger.warn "⚠️  Cloudflare not configured. Missing: #{missing.join(', ')}"
      return false
    end

    true
  end
end

