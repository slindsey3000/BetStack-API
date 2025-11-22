# UsageController - Public dashboard for API usage statistics
#
# Displays daily API request counts and league breakdowns
# Accessible at /usage (public, no authentication required)

class UsageController < ActionController::Base
  
  def index
    @stats = ApiUsageLog.stats_summary
    @today_total = @stats[:today]
    @month_total = @stats[:month]
    @daily_breakdown = @stats[:daily]
    @league_breakdown = @stats[:by_league_last_30_days]
    
    # Calculate some additional metrics
    @avg_daily_last_30 = calculate_avg_daily(30)
    @projected_monthly = @avg_daily_last_30 * 30
    
    respond_to do |format|
      format.html # renders app/views/usage/index.html.erb
      format.json { render json: @stats }
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

