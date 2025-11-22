# API Usage Tracking System

## Overview
The BetStack API now includes a comprehensive usage tracking system to monitor all requests made to The Odds API. This helps you stay within quota limits and identify usage patterns.

## Features

### 1. Automated Tracking
- Every API request to The Odds API is automatically logged
- Tracks daily aggregated counts per league
- Minimal performance overhead (atomic increments)
- Failure-safe (tracking errors don't break API calls)

### 2. Public Dashboard
A simple, visual dashboard accessible at:
- **Local:** http://localhost:3004/usage
- **Production:** https://betstack-45ae7ff725cd.herokuapp.com/usage
- **Edge:** https://api.betstack.dev/usage

The dashboard displays:
- Today's total requests
- Current month's total requests
- 30-day average (daily)
- Projected monthly usage
- Breakdown by league (last 30 days)
- Daily history (last 90 days)

### 3. Data Retention
- Detailed logs kept for 90 days
- Automatic cleanup runs daily at 3am UTC
- Configurable retention period

## Database Schema

```ruby
create_table :api_usage_logs do |t|
  t.date :date, null: false          # The day of usage
  t.string :league_key, null: false  # League identifier (e.g., 'basketball_nba')
  t.integer :request_count, default: 0, null: false
  t.timestamps
end

add_index :api_usage_logs, [:date, :league_key], unique: true
add_index :api_usage_logs, :date
```

## API Endpoints

### HTML Dashboard
```
GET /usage
```
Returns an HTML dashboard with charts and statistics.

### JSON API
```
GET /usage.json
```
Returns usage data in JSON format:
```json
{
  "today": 150,
  "month": 4523,
  "daily": {
    "2025-11-22": 150,
    "2025-11-21": 145,
    ...
  },
  "by_league_last_30_days": {
    "basketball_nba": 2341,
    "americanfootball_nfl": 1523,
    ...
  }
}
```

## Model Methods

```ruby
# Get total requests for today
ApiUsageLog.today_total
# => 150

# Get total requests for current month
ApiUsageLog.month_total
# => 4523

# Get daily breakdown for last N days (default: 30)
ApiUsageLog.daily_breakdown(30)
# => { Date('2025-11-22') => 150, ... }

# Get league breakdown for date range
ApiUsageLog.league_breakdown(30.days.ago.to_date, Date.current)
# => { "basketball_nba" => 2341, ... }

# Get complete stats summary
ApiUsageLog.stats_summary
# => { today: 150, month: 4523, daily: {...}, by_league_last_30_days: {...} }
```

## How It Works

### 1. Tracking Integration
When `OddsApiClient` makes a request:

```ruby
def fetch_odds(sport_key, ...)
  response = @connection.get(...)
  
  # Track usage in database
  track_usage(sport_key)
  
  JSON.parse(response.body)
end

def track_usage(league_key)
  ApiUsageLog.increment_for(league_key)
rescue => e
  Rails.logger.error "Failed to track API usage: #{e.message}"
end
```

### 2. Atomic Increments
Uses `find_or_create_by` + `increment!` for thread-safe counting:

```ruby
def self.increment_for(league_key, date = Date.current)
  record = find_or_create_by(date: date, league_key: league_key)
  record.increment!(:request_count)
  record
end
```

### 3. Automatic Cleanup
Scheduled job runs daily:

```ruby
class CleanupOldUsageLogsJob < ApplicationJob
  def perform
    cutoff_date = 90.days.ago.to_date
    deleted_count = ApiUsageLog.where("date < ?", cutoff_date).delete_all
    Rails.logger.info "✅ Deleted #{deleted_count} old usage log records"
  end
end
```

## Current Quota
- **Monthly Limit:** 100,000 requests
- **Dashboard shows:** Current usage vs. limit
- **Alerts:** Dashboard highlights high usage days

## Monitoring Best Practices

1. **Check Daily:** Visit the dashboard daily to monitor trends
2. **Watch Projections:** The projected monthly total warns if you're trending toward the limit
3. **League Analysis:** Identify which leagues consume the most quota
4. **Optimize:** Adjust Smart Scheduler frequency if needed

## Example Usage Patterns

Based on current setup:
- **Smart Scheduler:** ~48-720 requests/day per active league
- **Manual Syncs:** Spike in usage (avoid frequent manual syncs)
- **Expected Monthly:** 5,000-15,000 requests (well under 100k limit)

## Files Modified/Created

### New Files
- `app/models/api_usage_log.rb` - Model with helper methods
- `app/controllers/usage_controller.rb` - Dashboard controller
- `app/views/usage/index.html.erb` - Dashboard view
- `app/views/layouts/application.html.erb` - Layout for web views
- `app/jobs/cleanup_old_usage_logs_job.rb` - Cleanup job
- `db/migrate/TIMESTAMP_create_api_usage_logs.rb` - Migration

### Modified Files
- `app/services/odds_api_client.rb` - Added tracking calls
- `config/routes.rb` - Added `/usage` route
- `config/recurring.yml` - Added cleanup job schedule

## Future Enhancements

Possible improvements:
- Email alerts when approaching quota
- Hourly granularity (currently daily)
- Request type breakdown (odds vs scores)
- Export to CSV
- Historical trend charts (JavaScript charting library)

## Troubleshooting

### Dashboard shows 0 requests
- Tracking only starts after this deployment
- Make an API call: `SyncLeagueOddsJob.perform_now('basketball_nba')`
- Check logs for tracking errors

### Cleanup not running
- Verify `CleanupOldUsageLogsJob` in `config/recurring.yml`
- Check Solid Queue is running: `heroku ps -a betstack`
- Run manually: `CleanupOldUsageLogsJob.perform_now`

### Dashboard not accessible
- Ensure migration ran: `heroku run rails db:migrate -a betstack`
- Check route exists: `rails routes | grep usage`
- Verify controller exists: `ls app/controllers/usage_controller.rb`

## Support

For issues or questions:
1. Check Heroku logs: `heroku logs --tail -a betstack | grep -i usage`
2. Review model in Rails console: `ApiUsageLog.stats_summary`
3. Verify data: `ApiUsageLog.count`

