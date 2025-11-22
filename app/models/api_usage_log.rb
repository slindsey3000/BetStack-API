# ApiUsageLog - Tracks daily external API request counts
#
# Stores aggregated counts per league per day to monitor quota usage
# and identify which leagues consume the most API requests.

class ApiUsageLog < ApplicationRecord
  # Validations
  validates :date, presence: true
  validates :league_key, presence: true
  validates :request_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :for_date, ->(date) { where(date: date) }
  scope :for_league, ->(league_key) { where(league_key: league_key) }
  scope :recent, ->(days = 30) { where("date >= ?", days.days.ago.to_date) }
  scope :this_month, -> { where("date >= ?", Date.current.beginning_of_month) }

  # Increment the request count for a specific date and league
  # Uses atomic increment to avoid race conditions
  def self.increment_for(league_key, date = Date.current)
    record = find_or_create_by(date: date, league_key: league_key)
    record.increment!(:request_count)
    record
  end

  # Get total requests for today
  def self.today_total
    for_date(Date.current).sum(:request_count)
  end

  # Get total requests for current month
  def self.month_total
    this_month.sum(:request_count)
  end

  # Get daily breakdown for the last N days
  # Returns hash: { date => total_count }
  def self.daily_breakdown(days = 30)
    recent(days)
      .group(:date)
      .sum(:request_count)
      .sort_by { |date, _count| date }
      .reverse
      .to_h
  end

  # Get league breakdown for a date range
  # Returns hash: { league_key => total_count }
  def self.league_breakdown(start_date, end_date)
    where(date: start_date..end_date)
      .group(:league_key)
      .sum(:request_count)
      .sort_by { |_league, count| -count }
      .to_h
  end

  # Get detailed stats for dashboard
  def self.stats_summary
    {
      today: today_total,
      month: month_total,
      daily: daily_breakdown(90),
      by_league_last_30_days: league_breakdown(30.days.ago.to_date, Date.current)
    }
  end
end

