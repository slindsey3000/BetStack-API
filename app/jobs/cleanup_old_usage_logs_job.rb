# CleanupOldUsageLogsJob - Deletes API usage logs older than 90 days
#
# Runs daily to maintain data retention policy and keep database size manageable
# Scheduled in config/recurring.yml

class CleanupOldUsageLogsJob < ApplicationJob
  queue_as :default

  def perform
    cutoff_date = 90.days.ago.to_date
    
    Rails.logger.info "🧹 Cleaning up API usage logs older than #{cutoff_date}..."
    
    deleted_count = ApiUsageLog.where("date < ?", cutoff_date).delete_all
    
    Rails.logger.info "✅ Deleted #{deleted_count} old usage log records"
    
    deleted_count
  end
end

