# ⚡ League Optimization: Major North American Leagues Only

**Date:** October 31, 2025  
**Status:** ✅ Implemented and Deployed (v9)

---

## 🎯 Optimization Goal

Reduced data syncing from **73 leagues** to **6 major North American leagues** to significantly decrease API quota usage and focus on the most popular sports.

---

## ✅ Focused Leagues (6 total)

The system now only syncs these major leagues:

| League | Key | Sport |
|--------|-----|-------|
| **NBA** | `basketball_nba` | National Basketball Association |
| **NFL** | `americanfootball_nfl` | National Football League |
| **NHL** | `icehockey_nhl` | National Hockey League |
| **MLB** | `baseball_mlb` | Major League Baseball |
| **NCAAF** | `americanfootball_ncaaf` | College Football |
| **NCAAB** | `basketball_ncaab` | College Basketball |

---

## 📊 API Quota Impact

### Before Optimization (All 73 Leagues)
- **3x daily odds sync:** 219 requests/day
- **Hourly scores sync:** 1,752 requests/day
- **Total:** ~1,971 requests/day (~59,130/month) ❌ 118x over limit

### After Optimization (6 Major Leagues)
- **3x daily odds sync:** 18 requests/day
- **Hourly scores sync:** 144 requests/day
- **Total:** ~162 requests/day (~4,860/month) ⚠️ Still 10x over limit

### 🚨 Current Issue
Even with only 6 leagues, **hourly score syncing** uses 144 requests/day, which still exceeds the 500 request/month limit.

---

## 💡 Recommended Sync Frequencies

To stay within the 500 request/month limit, consider these options:

### Option 1: CONSERVATIVE ✅ (Recommended)
**~360 requests/month** - Comfortably under limit

```yaml
# config/recurring.yml
production:
  sync_odds_morning:
    class: SyncAllOddsJob
    schedule: at 8am every day          # 1x daily
  
  sync_scores:
    class: SyncScoresJob
    schedule: at 8pm every day          # 1x daily (evening)
```

**Pros:**
- Stays well under quota
- Still provides daily updates for odds and scores
- Reliable and predictable usage

**Cons:**
- Less frequent updates (may miss mid-day line movements)
- Scores only updated once per day

---

### Option 2: MODERATE ⚠️
**~540 requests/month** - Slightly over limit (8%)

```yaml
# config/recurring.yml
production:
  sync_odds_morning:
    class: SyncAllOddsJob
    schedule: at 8am every day          # Morning
  
  sync_odds_afternoon:
    class: SyncAllOddsJob
    schedule: at 2pm every day          # Afternoon
  
  sync_scores:
    class: SyncScoresJob
    schedule: at 8pm every day          # 1x daily
```

**Pros:**
- 2x daily odds updates (morning and afternoon)
- Catches line movements throughout the day
- Daily score updates

**Cons:**
- Slightly over quota (need to monitor usage)

---

### Option 3: BALANCED ⚠️
**~720 requests/month** - Over limit (44%)

```yaml
# config/recurring.yml (CURRENT)
production:
  sync_odds_morning:
    class: SyncAllOddsJob
    schedule: at 8am every day
  
  sync_odds_afternoon:
    class: SyncAllOddsJob
    schedule: at 2pm every day
  
  sync_odds_evening:
    class: SyncAllOddsJob
    schedule: at 8pm every day
  
  sync_scores:
    class: SyncScoresJob
    schedule: at 8pm every day          # 1x daily
```

**Pros:**
- 3x daily odds updates (comprehensive coverage)
- Daily score updates
- Good for development/testing

**Cons:**
- 44% over quota
- Requires API plan upgrade or additional requests

---

### Option 4: UPGRADE API PLAN 💰
**Unlimited** - No quota concerns

- Visit: https://the-odds-api.com/pricing
- Check higher tier plans
- Allows full 3x daily odds + hourly scores
- Best for production with high user traffic

---

## 🔧 Implementation Details

### Code Changes

#### 1. League Model (`app/models/league.rb`)
Added constant and scope for major leagues:

```ruby
MAJOR_NORTH_AMERICAN_LEAGUES = [
  'basketball_nba',       # NBA
  'americanfootball_nfl', # NFL
  'icehockey_nhl',        # NHL
  'baseball_mlb',         # MLB
  'americanfootball_ncaaf', # NCAAF
  'basketball_ncaab'      # NCAAB
].freeze

scope :major_north_american, -> { where(key: MAJOR_NORTH_AMERICAN_LEAGUES) }
```

#### 2. SyncAllOddsJob (`app/jobs/sync_all_odds_job.rb`)
Changed from `League.active` to `League.major_north_american`

#### 3. SyncScoresJob (`app/jobs/sync_scores_job.rb`)
Changed from `League.active` to `League.major_north_american`

#### 4. Rake Tasks (`lib/tasks/odds.rake`)
Updated `odds:seed` and `odds:sync` to use major leagues

---

## 📈 Database Impact

### Before
- All 73 leagues synced
- Events from international and niche sports
- Higher storage usage

### After
- 6 leagues actively synced
- Focused on North American major sports
- More relevant data for typical users

### Current Stats
```
Sports:      12
Leagues:     73 (6 actively syncing)
Teams:       232
Events:      143 (from 6 major leagues)
Lines:       919 (from 6 major leagues)
Bookmakers:  9

Top Leagues:
  • NCAAF:  65 events
  • NFL:    27 events
  • NBA:    22 events
  • NHL:    15 events
  • NCAAB:  8 events
  • MLB:    1 event
```

---

## 🚀 Deployment

### Heroku Status
- **Release:** v9
- **Deployed:** October 31, 2025
- **Status:** ✅ Live and running
- **URL:** https://betstack-45ae7ff725cd.herokuapp.com/

### Environment Variables
No changes needed - same API key and configuration

---

## ⚠️ Important Notes

### 1. API Quota Still Exceeds Limit
With current configuration (3x daily odds + hourly scores), you'll exceed the 500 request/month limit in ~3 days.

**Action Required:**
- Choose one of the recommended sync frequencies above, OR
- Upgrade your The Odds API plan

### 2. Other Leagues Still in Database
All 73 leagues remain in the database but only 6 are actively synced. To manually sync other leagues:

```bash
rails "odds:sync_league[soccer_epl]"  # Example: English Premier League
```

### 3. Seasonal Adjustments
Consider adjusting which leagues sync based on season:
- **Fall/Winter:** Focus on NFL, NBA, NHL, NCAAF, NCAAB
- **Spring/Summer:** Focus on MLB, NBA playoffs
- **Off-season:** Reduce frequency or pause syncing

---

## 📝 Next Steps

### Immediate
1. **Decide on sync frequency** - Choose from options above
2. **Update `config/recurring.yml`** if changing frequency
3. **Monitor API usage** - Check quota in logs and API dashboard
4. **Redeploy if needed** - `git push heroku main`

### Short-term
1. Add monitoring for API quota usage
2. Implement alerts when approaching limit
3. Consider caching strategies to reduce API calls

### Long-term
1. Upgrade API plan if user base grows
2. Add per-league configuration (enable/disable syncing)
3. Implement smart syncing (only active games during season)
4. Add user preferences (let users choose leagues to follow)

---

## 🔄 Rolling Back

To sync all 73 leagues again:

```ruby
# In app/jobs/sync_all_odds_job.rb
# Change:
major_leagues = League.major_north_american.to_a

# Back to:
active_leagues = League.active.to_a
```

---

## 📚 Related Documentation

- **API Pricing:** https://the-odds-api.com/pricing
- **API Documentation:** https://the-odds-api.com/liveapi/guides/v4/
- **Data Ingestion Complete:** `DATA_INGESTION_COMPLETE.md`
- **Setup Complete:** `SETUP_COMPLETE.md`

---

**Status:** ✅ Optimization deployed, awaiting sync frequency decision to stay under API quota

