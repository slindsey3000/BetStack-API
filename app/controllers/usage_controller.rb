# UsageController - Public dashboard for API usage statistics
#
# Displays:
# 1. Internal API usage (requests to external data providers like The Odds API)
# 2. Client API usage (requests from API key holders hitting our API)
#
# Accessible at /usage (public, no authentication required)

class UsageController < ActionController::Base
  helper_method :obfuscate_email
  
  def index
    # Internal API usage (our requests to The Odds API)
    @internal_stats = ApiUsageLog.stats_summary
    @today_total = @internal_stats[:today]
    @month_total = @internal_stats[:month]
    @daily_breakdown = @internal_stats[:daily]
    @league_breakdown = @internal_stats[:by_league_last_30_days]
    
    # Calculate some additional metrics for internal usage
    @avg_daily_last_30 = calculate_avg_daily(30)
    @projected_monthly = @avg_daily_last_30 * 30
    
    # Client API usage (requests from API key holders)
    @client_stats = ClientApiUsage.stats_summary
    @client_today_requests = @client_stats[:today_requests]
    @client_today_rejected = @client_stats[:today_rejected]
    @client_month_requests = @client_stats[:month_requests]
    @client_daily_breakdown = @client_stats[:daily]
    
    # Usage breakdown by user/email (for admin view)
    @client_usage_by_email = ClientApiUsage.usage_by_email(30)
    @client_top_abusers = ClientApiUsage.top_abusers(30, 10)
    
    respond_to do |format|
      format.html # renders app/views/usage/index.html.erb
      format.json { render json: { internal: @internal_stats, client: @client_stats } }
    end
  end
  
  private
  
  def calculate_avg_daily(days)
    logs = ApiUsageLog.recent(days)
    return 0 if logs.empty?
    
    total = logs.sum(:request_count)
    days_with_data = logs.pluck(:date).uniq.count
    days_with_data > 0 ? (total.to_f / days_with_data).round : 0
  end
  
  # Obfuscate email for display: "john.doe@example.com" -> "j***e@e***.com"
  def obfuscate_email(email)
    return 'unknown' if email.blank? || email == 'unknown'
    
    local, domain = email.split('@')
    return email if local.nil? || domain.nil?
    
    # Obfuscate local part: keep first and last char
    if local.length <= 2
      obfuscated_local = local[0] + '*'
    else
      obfuscated_local = local[0] + ('*' * [local.length - 2, 3].min) + local[-1]
    end
    
    # Obfuscate domain: keep first char and TLD
    domain_parts = domain.split('.')
    if domain_parts.length >= 2
      tld = domain_parts.last
      domain_name = domain_parts[0..-2].join('.')
      if domain_name.length <= 2
        obfuscated_domain = domain_name[0] + '*'
      else
        obfuscated_domain = domain_name[0] + ('*' * [domain_name.length - 1, 3].min)
      end
      obfuscated_domain += '.' + tld
    else
      obfuscated_domain = domain[0] + '***'
    end
    
    "#{obfuscated_local}@#{obfuscated_domain}"
  end
end

