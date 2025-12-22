# UsageController - Public dashboard for API usage statistics
#
# Displays:
# 1. Internal API usage (requests to external data providers like The Odds API)
# 2. Client API usage (requests from API key holders hitting our API)
#
# Accessible at /usage (public, no authentication required)

class UsageController < ActionController::Base
  
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
end

