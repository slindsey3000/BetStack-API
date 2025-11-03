# SyncCloudflareCacheStaticJob - Syncs static endpoints (sports, leagues, teams) less frequently
# Runs every 30 minutes since these change rarely

class SyncCloudflareCacheStaticJob < ApplicationJob
  queue_as :default

  def perform
    return unless cloudflare_configured?

    Rails.logger.info "🌐 Starting Cloudflare cache sync (STATIC endpoints)..."
    
    syncer = CloudflareCacheSyncer.new
    
    # Sync only static endpoints (sports, leagues, teams, bookmakers)
    syncer.sync_all_endpoints(priority: :static)
    
    # Also sync API keys (rarely changes, but check periodically)
    syncer.sync_api_keys
    
    Rails.logger.info "✅ Cloudflare cache sync (STATIC) complete"
  rescue => e
    Rails.logger.error "❌ Cloudflare cache sync (STATIC) failed: #{e.message}"
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

