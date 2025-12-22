# AdminMailer - Internal admin notifications
#
# Sends daily usage reports and other admin notifications

class AdminMailer < ApplicationMailer
  default from: 'BetStack Support <support@betstack.dev>'

  # Daily usage report email
  def daily_usage_report(to_email)
    @date = Date.yesterday
    @generated_at = Time.current
    
    # Client API Usage (requests from API key holders)
    @client_today = ClientApiUsage.for_date(@date).sum(:request_count)
    @client_rejected = ClientApiUsage.for_date(@date).sum(:rejected_count)
    @client_month = ClientApiUsage.this_month.sum(:request_count)
    @client_by_email = ClientApiUsage.for_date(@date)
                                      .group(:email)
                                      .select('email, SUM(request_count) as requests, SUM(rejected_count) as rejected')
                                      .order('requests DESC')
                                      .limit(10)
                                      .map { |r| { email: r.email, requests: r.requests, rejected: r.rejected } }
    
    # Internal API Usage (our requests to The Odds API)
    @internal_today = ApiUsageLog.for_date(@date).sum(:request_count)
    @internal_month = ApiUsageLog.this_month.sum(:request_count)
    @internal_by_league = ApiUsageLog.for_date(@date)
                                      .group(:league_key)
                                      .sum(:request_count)
                                      .sort_by { |_, v| -v }
                                      .first(10)
                                      .to_h
    
    # User stats
    @total_users = User.where(deleted_at: nil).count
    @active_users = User.valid.count
    @new_users_today = User.where(deleted_at: nil).where('DATE(created_at) = ?', @date).count
    
    # Top abusers (if any)
    @top_abusers = ClientApiUsage.for_date(@date)
                                  .where('rejected_count > 0')
                                  .group(:email)
                                  .select('email, SUM(rejected_count) as rejected')
                                  .order('rejected DESC')
                                  .limit(5)
                                  .map { |r| { email: r.email, rejected: r.rejected } }
    
    mail(
      to: to_email,
      subject: "BetStack API Daily Report - #{@date.strftime('%B %d, %Y')}"
    )
  end
end

