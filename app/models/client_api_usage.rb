# ClientApiUsage - Tracks client API usage by API key and email
#
# Stores hourly aggregated counts for:
# - request_count: Successful API requests
# - rejected_count: Rate-limited requests (abuse tracking)
#
# Data is synced hourly from Cloudflare KV edge counters

class ClientApiUsage < ApplicationRecord
  # Validations
  validates :date, presence: true
  validates :hour, presence: true, inclusion: { in: 0..23 }
  validates :api_key, presence: true
  validates :email, presence: true
  validates :request_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rejected_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :for_date, ->(date) { where(date: date) }
  scope :for_email, ->(email) { where(email: email) }
  scope :for_api_key, ->(api_key) { where(api_key: api_key) }
  scope :recent, ->(days = 30) { where("date >= ?", days.days.ago.to_date) }
  scope :today, -> { for_date(Date.current) }
  scope :this_month, -> { where("date >= ?", Date.current.beginning_of_month) }

  # Upsert usage data (find or create, then increment)
  def self.record_usage(date:, hour:, api_key:, email:, requests: 0, rejected: 0)
    record = find_or_initialize_by(date: date, hour: hour, api_key: api_key)
    record.email = email
    record.request_count = (record.request_count || 0) + requests
    record.rejected_count = (record.rejected_count || 0) + rejected
    record.save!
    record
  end

  # ==========================================
  # Aggregate Statistics
  # ==========================================

  # Total requests today
  def self.today_total_requests
    today.sum(:request_count)
  end

  # Total rejected today
  def self.today_total_rejected
    today.sum(:rejected_count)
  end

  # Total requests this month
  def self.month_total_requests
    this_month.sum(:request_count)
  end

  # Daily breakdown for last N days
  # Returns hash: { date => { requests: N, rejected: N } }
  def self.daily_breakdown(days = 30)
    recent(days)
      .group(:date)
      .select('date, SUM(request_count) as total_requests, SUM(rejected_count) as total_rejected')
      .order(date: :desc)
      .map { |r| [r.date, { requests: r.total_requests, rejected: r.total_rejected }] }
      .to_h
  end

  # Usage by email (for admin console)
  def self.usage_by_email(days = 7)
    recent(days)
      .group(:email)
      .select('email, SUM(request_count) as total_requests, SUM(rejected_count) as total_rejected')
      .order('total_requests DESC')
      .map { |r| { email: r.email, requests: r.total_requests, rejected: r.total_rejected } }
  end

  # Top abusers (most rejected requests)
  def self.top_abusers(days = 7, limit = 10)
    recent(days)
      .where('rejected_count > 0')
      .group(:email)
      .select('email, SUM(rejected_count) as total_rejected, SUM(request_count) as total_requests')
      .order('total_rejected DESC')
      .limit(limit)
      .map { |r| { email: r.email, rejected: r.total_rejected, requests: r.total_requests } }
  end

  # Stats summary for dashboard
  def self.stats_summary
    {
      today_requests: today_total_requests,
      today_rejected: today_total_rejected,
      month_requests: month_total_requests,
      daily: daily_breakdown(30)
    }
  end

  # Cleanup old records (keep 90 days)
  def self.cleanup_old_records(days_to_keep = 90)
    where("date < ?", days_to_keep.days.ago.to_date).delete_all
  end
end
