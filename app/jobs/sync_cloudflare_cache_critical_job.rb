# SyncCloudflareCacheCriticalJob - Syncs critical endpoints (lines, events) frequently
# Runs every 2 minutes to keep dynamic betting data fresh at the edge

class SyncCloudflareCacheCriticalJob < ApplicationJob
  queue_as :default

  def perform
    return unless cloudflare_configured?

    Rails.logger.info "🌐 Starting Cloudflare cache sync (CRITICAL endpoints)..."
    
    syncer = CloudflareCacheSyncer.new
    
    # Sync only critical endpoints (lines, events, results)
    syncer.sync_all_endpoints(priority: :critical)
    
    Rails.logger.info "✅ Cloudflare cache sync (CRITICAL) complete"
  rescue => e
    Rails.logger.error "❌ Cloudflare cache sync (CRITICAL) failed: #{e.message}"
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

