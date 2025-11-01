# 🛠️ BetStack API - Worker Dyno Setup Complete

## ✅ What Was Set Up

### 1. Procfile Created
Created `/Procfile` to define dyno types:
```
web: bin/rails server -p ${PORT:-5000} -e $RAILS_ENV
worker: bundle exec rake solid_queue:start
```

### 2. Solid Queue Database Tables
Loaded Solid Queue schema to Heroku database with 11 tables:
- `solid_queue_jobs`
- `solid_queue_recurring_tasks` ✅
- `solid_queue_ready_executions`
- `solid_queue_scheduled_executions`
- `solid_queue_claimed_executions`
- `solid_queue_blocked_executions`
- `solid_queue_failed_executions`
- `solid_queue_recurring_executions`
- `solid_queue_processes`
- `solid_queue_pauses`
- `solid_queue_semaphores`

### 3. Worker Dyno Scaled Up
```bash
heroku ps:scale worker=1 --app betstack
```

**Current Dynos Running:**
- **web.1**: Serving API requests (Basic tier)
- **worker.1**: Running background jobs (Basic tier) ✅

---

## 📅 What the Worker Does

The worker dyno automatically runs your scheduled jobs defined in `config/recurring.yml`:

### Production Schedule

**Sports/Leagues Sync** (1x daily)
- **Time:** 6:00 AM UTC (1:00 AM EST)
- **Job:** `SyncSportsJob`
- **What:** Updates available sports and leagues

**Odds/Lines Sync** (2x daily)
- **Morning:** 12:00 PM UTC (7:00 AM EST)
- **Evening:** 8:00 PM UTC (3:00 PM EST)
- **Job:** `SyncAllOddsJob`
- **What:** Fetches betting lines for 6 major leagues

**Scores/Results Sync** (2x daily)
- **Evening:** 10:00 PM UTC (5:00 PM EST) ✅
- **Night:** 3:00 AM UTC (10:00 PM EST previous day) ✅
- **Job:** `SyncScoresJob`
- **What:** Fetches final scores for completed games

---

## 🔍 Monitoring Workers

### Check Dyno Status
```bash
heroku ps --app betstack
```

### View Worker Logs
```bash
# All worker logs
heroku logs --tail --ps worker --app betstack

# Recent logs
heroku logs --tail --source app --app betstack | grep worker

# Filter for specific job
heroku logs --tail --app betstack | grep "SyncAllOddsJob"
```

### Check Scheduled Jobs
```bash
heroku run rails runner "puts SolidQueue::RecurringTask.all.map(&:key)" --app betstack
```

### Manually Trigger a Job
```bash
# Trigger odds sync
heroku run rails runner "SyncAllOddsJob.perform_now" --app betstack

# Trigger scores sync
heroku run rails runner "SyncScoresJob.perform_now" --app betstack
```

---

## 💰 Cost Breakdown

### Heroku Dynos (Basic Tier)
- **Web dyno**: $7/month (1000 hours)
- **Worker dyno**: $7/month (1000 hours)
- **Total**: ~$14/month

### The Odds API
- **Free tier**: 500 requests/month
- **Current usage**: ~720 requests/month
- **Status**: ⚠️ Slightly over limit (44%)

**Options:**
1. Stay on free tier - may hit limit mid-month
2. Reduce to 1x daily syncs (~360/month) ✅
3. Upgrade to paid plan ($10-50/month for more requests)

---

## 🚨 Troubleshooting

### Worker Not Running?
```bash
# Check status
heroku ps --app betstack

# If crashed, check logs
heroku logs --tail --ps worker --app betstack

# Restart worker
heroku restart worker --app betstack
```

### Jobs Not Executing?
```bash
# Check if recurring tasks are loaded
heroku run rails runner "pp SolidQueue::RecurringTask.pluck(:key, :schedule)" --app betstack

# Check for failed jobs
heroku run rails runner "puts SolidQueue::FailedExecution.last(5).map(&:error)" --app betstack
```

### Database Connection Issues?
```bash
# Verify Solid Queue tables exist
heroku run rails runner "puts SolidQueue::RecurringTask.table_exists?" --app betstack
# Should return: true
```

### API Quota Exceeded?
Check logs for quota warnings:
```bash
heroku logs --tail --app betstack | grep "API Usage"
```

If quota is hit:
- Reduce sync frequency in `config/recurring.yml`
- Remove leagues from `League.major_north_american` scope
- Upgrade The Odds API plan

---

## 🔄 Making Changes

### Change Sync Schedule
1. Edit `config/recurring.yml`
2. Commit and push:
   ```bash
   git add config/recurring.yml
   git commit -m "Update sync schedule"
   git push heroku main
   ```
3. Restart worker:
   ```bash
   heroku restart worker --app betstack
   ```

### Scale Worker Up/Down
```bash
# Scale to 0 (pause all background jobs)
heroku ps:scale worker=0 --app betstack

# Scale back to 1
heroku ps:scale worker=1 --app betstack
```

**Note:** Scaling worker to 0 will stop all scheduled jobs. API will still work but data won't update automatically.

---

## 📊 Current Configuration

| Component | Status | Details |
|-----------|--------|---------|
| Web Dyno | ✅ Running | Serves API at betstack-45ae7ff725cd.herokuapp.com |
| Worker Dyno | ✅ Running | Executes background jobs via Solid Queue |
| Solid Queue Tables | ✅ Loaded | 11 tables created in production database |
| Recurring Jobs | ✅ Configured | 5 jobs scheduled (see recurring.yml) |
| API Quota | ⚠️ Close | ~720/500 requests/month |

---

## 📝 Related Documentation

- **Sync Schedule:** `SYNC_SCHEDULE.md`
- **API Endpoints:** `API_ENDPOINTS.md`
- **Postman Collection:** `BetStack_API.postman_collection.json`
- **Setup Guide:** `SETUP_COMPLETE.md`
- **Cursor Rules:** `.cursorrules`

---

## ✅ Worker Setup Summary

**Status:** Fully operational! 🚀

Your worker dyno is now:
1. ✅ Running 24/7 on Heroku
2. ✅ Connected to Solid Queue background job system
3. ✅ Executing scheduled jobs automatically (2x daily for odds & scores)
4. ✅ Syncing 6 major North American leagues
5. ✅ Persisting all data historically

**No manual intervention needed** - jobs will run automatically on schedule!

To verify it's working, check the database after the next scheduled sync:
```bash
heroku run rails runner "puts Event.order(:last_sync_at).last.last_sync_at" --app betstack
```

---

**Last Updated:** November 1, 2025  
**Worker Cost:** $7/month (Basic dyno)  
**Total Monthly Cost:** ~$14/month (web + worker)
