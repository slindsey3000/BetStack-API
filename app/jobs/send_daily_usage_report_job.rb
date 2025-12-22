# SendDailyUsageReportJob - Sends daily usage report email
#
# Scheduled to run at 6am EST (11am UTC) daily
# Sends a summary of yesterday's API usage to admin

class SendDailyUsageReportJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Sending daily usage report email..."
    
    # Send to admin
    AdminMailer.daily_usage_report('slindsey3000@gmail.com').deliver_now
    
    Rails.logger.info "Daily usage report sent successfully"
  end
end

