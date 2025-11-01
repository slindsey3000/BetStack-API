# 📅 BetStack API - Data Sync Schedule

## Current Schedule (Production)

### Sports & Leagues
**Frequency:** Once daily  
**Time:** 6:00 AM UTC (1:00 AM EST)  
**Job:** `SyncSportsJob`  
**What it does:** Updates the list of available sports and leagues

---

### Odds/Lines Sync
**Frequency:** 2x daily  
**Times:**
- **Morning:** 12:00 PM UTC (7:00 AM EST)
- **Evening:** 8:00 PM UTC (3:00 PM EST)

**Job:** `SyncAllOddsJob`  
**What it syncs:** Betting lines from all bookmakers for 6 major leagues:
- NFL (americanfootball_nfl)
- NBA (basketball_nba)
- NHL (icehockey_nhl)
- MLB (baseball_mlb)
- NCAAF (americanfootball_ncaaf)
- NCAAB (basketball_ncaab)

---

### Scores/Results Sync
**Frequency:** 2x daily  
**Times:**
- **Evening:** 10:00 PM UTC (5:00 PM EST)
- **Night:** 3:00 AM UTC (10:00 PM EST previous day)

**Job:** `SyncScoresJob`  
**What it syncs:** Final scores and results for completed games in the 6 major leagues

---

## API Quota Usage

### Current Daily Usage
- Sports sync: 0 requests (free endpoint)
- Odds sync: 12 requests (6 leagues × 2 syncs)
- Scores sync: 12 requests (6 leagues × 2 syncs)
- **Total: 24 requests/day**

### Monthly Estimate
- **~720 requests/month**
- Within 500/month limit? ⚠️ Slightly over (44%)
- **Recommendation:** This is close to the limit. Monitor usage.

### To Reduce Usage Further
If you need to stay under 500/month, reduce to:
- 1x daily odds sync (6 requests/day)
- 1x daily scores sync (6 requests/day)
- **Total: 12 requests/day = ~360/month** ✅

---

## How to Change the Schedule

### Quick Changes
Edit `config/recurring.yml` and change the schedule strings:

**Example: Reduce to 1x daily**
```yaml
sync_odds_daily:
  class: SyncAllOddsJob
  schedule: at 2pm every day  # 9am EST
```

**Example: Increase to 3x daily**
```yaml
sync_odds_morning:
  schedule: at 12pm every day  # 7am EST

sync_odds_afternoon:
  schedule: at 5pm every day   # 12pm EST

sync_odds_evening:
  schedule: at 8pm every day   # 3pm EST
```

**Example: Change to specific hours**
```yaml
sync_scores:
  schedule: every 4 hours  # Runs at 12am, 4am, 8am, 12pm, 4pm, 8pm UTC
```

---

## Schedule Syntax Reference

### Time-based
- `at 8am every day` - Daily at 8am UTC
- `at 2:30pm every day` - Daily at 2:30pm UTC
- `at 11pm on sunday` - Weekly on Sunday at 11pm UTC

### Interval-based
- `every hour` - Every hour
- `every 2 hours` - Every 2 hours
- `every 30 minutes` - Every 30 minutes
- `every day` - Once per day (midnight UTC)

### Complex
- `every 3 hours between 9am and 6pm` - Business hours only
- `at 10am on monday, wednesday, friday` - Specific days

---

## Timezone Reference

### EST to UTC Conversion
EST is UTC-5 (EST + 5 = UTC)

| EST Time | UTC Time |
|----------|----------|
| 12:00 AM | 5:00 AM  |
| 5:00 AM  | 10:00 AM |
| 7:00 AM  | 12:00 PM |
| 12:00 PM | 5:00 PM  |
| 3:00 PM  | 8:00 PM  |
| 5:00 PM  | 10:00 PM |
| 10:00 PM | 3:00 AM (next day) |

**Note:** During EDT (Daylight Time), the offset is UTC-4

---

## Testing Schedule Changes

### Test Locally
```bash
# Start Rails console
rails c

# Manually trigger a job
SyncAllOddsJob.perform_now
SyncScoresJob.perform_now
```

### Deploy to Heroku
```bash
git add config/recurring.yml
git commit -m "Update sync schedule"
git push heroku main
```

### Check Running Jobs
```bash
# Local
rails solid_queue:status

# Heroku
heroku run rails solid_queue:status --app betstack
```

---

## Monitoring

### Check Last Sync
```bash
# Rails console
Event.order(last_sync_at: :desc).first.last_sync_at
```

### View Job Logs
```bash
# Heroku logs
heroku logs --tail --ps worker --app betstack

# Or all logs
heroku logs --tail --app betstack | grep "sync"
```

### Check API Quota
Look for log entries like:
```
API Usage - GET /sports/americanfootball_nfl/odds: Used=24, Remaining=476, Cost=3
```

---

## Troubleshooting

### Jobs Not Running?
1. Check if Solid Queue is configured properly
2. Verify recurring.yml syntax
3. Restart Heroku dynos: `heroku restart --app betstack`

### Running Out of API Quota?
1. Reduce sync frequency (1x daily)
2. Remove leagues from sync (keep only NFL/NBA)
3. Upgrade The Odds API plan

### Old Data?
1. Check last_sync_at timestamps on events
2. Manually trigger sync: `heroku run rails odds:sync --app betstack`
3. Check Heroku logs for errors

---

## Configuration File

The schedule is defined in: `config/recurring.yml`

```yaml
production:
  sync_odds_morning:
    class: SyncAllOddsJob
    queue: default
    schedule: at 12pm every day  # 7am EST
```

Changes take effect on next deploy to Heroku.

---

**Last Updated:** November 1, 2025  
**Current Version:** 2x daily odds, 2x daily scores  
**API Usage:** ~24 requests/day (~720/month)
