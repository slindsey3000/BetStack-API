# SyncClientUsageJob - Syncs API usage data from Cloudflare KV to database
#
# Runs hourly to:
# 1. Read usage counters from Cloudflare KV (usage:{apiKey}:{hour})
# 2. Read abuse counters from Cloudflare KV (abuse:{apiKey}:{hour})
# 3. Look up email for each API key
# 4. Upsert to client_api_usages table
# 5. Delete processed keys from KV
#
# This allows tracking usage by email without hitting the database on every request

class SyncClientUsageJob < ApplicationJob
  queue_as :default

  def perform
    start_time = Time.current
    Rails.logger.info "Starting client usage sync from Cloudflare KV..."

    cache_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_KV_NAMESPACE_ID'])
    api_keys_client = CloudflareKvClient.new(namespace_id: ENV['CLOUDFLARE_API_KEYS_NAMESPACE_ID'])

    # Track stats
    usage_synced = 0
    abuse_synced = 0
    keys_to_delete = []
    email_cache = {} # Cache email lookups to avoid repeated KV reads

    # Sync usage counters (usage:{apiKey}:{hour})
    usage_keys = cache_client.list_keys(prefix: 'usage:')
    Rails.logger.info "Found #{usage_keys.count} usage keys to sync"

    usage_keys.each do |key|
      begin
        # Parse key: usage:{apiKey}:{hour}
        parts = key.split(':')
        next unless parts.length == 3 && parts[0] == 'usage'
        
        api_key = parts[1]
        hour_str = parts[2] # Format: "2025-12-22T15"
        
        # Parse date and hour from ISO format
        date = Date.parse(hour_str[0..9]) rescue nil
        hour = hour_str[11..12].to_i rescue nil
        next unless date && hour
        
        # Get usage count
        count_str = cache_client.get(key)
        count = count_str.to_i
        next if count == 0
        
        # Look up email for API key (with caching)
        email = email_cache[api_key] ||= lookup_email(api_keys_client, api_key)
        
        # Record usage
        ClientApiUsage.record_usage(
          date: date,
          hour: hour,
          api_key: api_key,
          email: email,
          requests: count,
          rejected: 0
        )
        
        usage_synced += 1
        keys_to_delete << key
      rescue => e
        Rails.logger.error "Failed to sync usage key #{key}: #{e.message}"
      end
    end

    # Sync abuse counters (abuse:{apiKey}:{hour})
    abuse_keys = cache_client.list_keys(prefix: 'abuse:')
    Rails.logger.info "Found #{abuse_keys.count} abuse keys to sync"

    abuse_keys.each do |key|
      begin
        # Parse key: abuse:{apiKey}:{hour}
        parts = key.split(':')
        next unless parts.length == 3 && parts[0] == 'abuse'
        
        api_key = parts[1]
        hour_str = parts[2] # Format: "2025-12-22T15"
        
        # Parse date and hour from ISO format
        date = Date.parse(hour_str[0..9]) rescue nil
        hour = hour_str[11..12].to_i rescue nil
        next unless date && hour
        
        # Get abuse count
        count_str = cache_client.get(key)
        count = count_str.to_i
        next if count == 0
        
        # Look up email for API key (with caching)
        email = email_cache[api_key] ||= lookup_email(api_keys_client, api_key)
        
        # Record abuse (rejected requests)
        ClientApiUsage.record_usage(
          date: date,
          hour: hour,
          api_key: api_key,
          email: email,
          requests: 0,
          rejected: count
        )
        
        abuse_synced += 1
        keys_to_delete << key
      rescue => e
        Rails.logger.error "Failed to sync abuse key #{key}: #{e.message}"
      end
    end

    # Delete processed keys from KV
    if keys_to_delete.any?
      Rails.logger.info "Deleting #{keys_to_delete.count} processed keys from KV..."
      cache_client.bulk_delete(keys_to_delete)
    end

    # Cleanup old records (older than 90 days)
    deleted_old = ClientApiUsage.cleanup_old_records(90)
    
    duration = Time.current - start_time
    Rails.logger.info "Client usage sync complete: #{usage_synced} usage records, #{abuse_synced} abuse records synced, #{deleted_old} old records cleaned up in #{duration.round(2)}s"
  end

  private

  def lookup_email(api_keys_client, api_key)
    key_data_str = api_keys_client.get(api_key)
    return 'unknown' unless key_data_str
    
    # Try to parse JSON format, fall back to 'legacy' for old format
    if key_data_str == 'valid'
      'legacy'
    else
      begin
        data = JSON.parse(key_data_str)
        data['email'] || 'unknown'
      rescue JSON::ParserError
        'unknown'
      end
    end
  end
end

