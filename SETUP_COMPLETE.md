# BetStack API - Setup Complete! ✅

## Environment Configuration Summary

### Local Development

**Environment Variables (`.env` file created):**
```
ODDS_API_KEY=9e998c3bca7eb84b2478a3741c6326a6
ODDS_API_BASE_URL=https://api.the-odds-api.com/v4
RAILS_ENV=development
```

**Gems Installed:**
- ✅ `faraday` - HTTP client for API requests
- ✅ `faraday-retry` - Automatic retry logic for failed requests
- ✅ `dotenv-rails` - Load environment variables from `.env`

**Database:**
- ✅ PostgreSQL database `betstack_api_development` created
- ✅ All migrations run successfully
- ✅ 7 tables created: sports, leagues, teams, events, bookmakers, lines, results

**API Connection Test:**
- ✅ Successfully connected to The Odds API
- ✅ Retrieved 75 active sports
- ✅ API quota: 500 requests remaining (0 used)

---

## Heroku Production Setup

**App Information:**
- **App Name:** `betstack`
- **Region:** US
- **URL:** https://betstack-45ae7ff725cd.herokuapp.com/
- **Stack:** heroku-24

**Environment Variables Set:**
```bash
heroku config -a betstack
```
- ✅ `ODDS_API_KEY` = 9e998c3bca7eb84b2478a3741c6326a6
- ✅ `ODDS_API_BASE_URL` = https://api.the-odds-api.com/v4

**Database:**
- ✅ PostgreSQL Essential-0 provisioned ($5/month max)
- ⏳ Database: `postgresql-concentric-78186` (currently provisioning)
- ⏳ Status: Creating (should be ready within a few minutes)

**Git Remote:**
- ✅ Heroku remote added: https://git.heroku.com/betstack.git

---

## Files Created

### Configuration Files
1. **`.env`** - Local environment variables (⚠️ NOT committed to git)
2. **`config/initializers/odds_api.rb`** - OddsApi configuration module
3. **`test_odds_api.rb`** - API connection test script

### Database Migrations (7 files)
1. `db/migrate/20251031193404_create_sports.rb`
2. `db/migrate/20251031193411_create_leagues.rb`
3. `db/migrate/20251031193418_create_teams.rb`
4. `db/migrate/20251031193428_create_events.rb`
5. `db/migrate/20251031193435_create_bookmakers.rb`
6. `db/migrate/20251031193441_create_lines.rb`
7. `db/migrate/20251031193449_create_results.rb`

### Models (7 files)
1. `app/models/sport.rb`
2. `app/models/league.rb`
3. `app/models/team.rb`
4. `app/models/event.rb`
5. `app/models/bookmaker.rb`
6. `app/models/line.rb`
7. `app/models/result.rb`

---

## Database Schema

### Tables Created

```ruby
sports
  - name, description, active
  - has_many :leagues

leagues  
  - sport_id, name, key, region, active, has_outrights
  - belongs_to :sport
  - has_many :teams, :events

teams
  - league_id, name, normalized_name, abbreviation, city, conference, division, active
  - belongs_to :league
  - has_many :home_events, :away_events

events
  - league_id, home_team_id, away_team_id, odds_api_id, home_team_name, away_team_name
  - commence_time, status, completed, preseason, last_sync_at
  - belongs_to :league, :home_team, :away_team
  - has_many :lines, has_one :result

bookmakers
  - key, name, description, region, active
  - has_many :lines

lines (flattened odds structure)
  - event_id, bookmaker_id, source
  - money_line_home, money_line_away, draw_line
  - point_spread_home, point_spread_away, point_spread_home_line, point_spread_away_line
  - total_number, over_line, under_line
  - last_updated, participant_data (jsonb)
  - belongs_to :event, :bookmaker

results
  - event_id, home_score, away_score, final
  - belongs_to :event
```

---

## API Configuration

### The Odds API Setup

**Base URL:** `https://api.the-odds-api.com/v4`

**Default Settings:**
- **Region:** `us` (United States bookmakers)
- **Odds Format:** `american` (e.g., +150, -110)
- **Markets:** `h2h`, `spreads`, `totals`

**Available Endpoints:**
- `GET /sports` - List all sports (free, doesn't count against quota)
- `GET /sports/{sport_key}/odds` - Get odds for a sport
- `GET /sports/{sport_key}/scores` - Get scores/results
- `GET /sports/{sport_key}/events` - Get upcoming events

**Rate Limiting:**
- Returns status 429 if rate limit exceeded
- Response headers include:
  - `x-requests-used`
  - `x-requests-remaining`
  - `x-requests-last`

---

## Testing

### Local API Test
```bash
ruby test_odds_api.rb
```

This script:
- ✅ Loads environment variables
- ✅ Connects to The Odds API
- ✅ Fetches all sports
- ✅ Displays active sports with details
- ✅ Shows remaining API quota

**Test Results:**
```
✅ API Connection Successful!
   - Status: 200
   - x-requests-remaining: 500
📊 Retrieved 75 sports
   Active Sports: NFL, NBA, MLB, NHL, NCAAF, and 70 more
```

---

## Next Steps

### 1. Wait for Heroku Database
The PostgreSQL database is currently provisioning. Check status:
```bash
heroku addons:info postgresql-concentric-78186 -a betstack
```

When state shows "available", you can deploy.

### 2. Deploy to Heroku
```bash
git add .
git commit -m "Initial commit: Database schema and API configuration"
git push heroku main
```

### 3. Run Migrations on Heroku
```bash
heroku run rails db:migrate -a betstack
```

### 4. Test API on Heroku
```bash
heroku run ruby test_odds_api.rb -a betstack
```

### 5. Build Data Ingestion Service
Next tasks:
- Create `OddsApiService` to fetch data from The Odds API
- Create `OddsDataIngester` to parse and populate database
- Build background jobs for scheduled syncs
- Create RESTful API endpoints to serve data

---

## Quick Reference Commands

### Local Development
```bash
# Start Rails console
rails console

# Run API test
ruby test_odds_api.rb

# Start Rails server
rails server

# Run migrations
rails db:migrate

# Check database status
rails db:migrate:status
```

### Heroku Commands
```bash
# View config
heroku config -a betstack

# View logs
heroku logs --tail -a betstack

# Run Rails console
heroku run rails console -a betstack

# Run migrations
heroku run rails db:migrate -a betstack

# Restart app
heroku restart -a betstack

# Check database status
heroku pg:info -a betstack
```

---

## Important Notes

⚠️ **Security:**
- `.env` file is gitignored and NOT committed
- API keys are stored as environment variables
- Never commit secrets to version control

📊 **API Quota:**
- Current plan: 500 requests/month
- `/sports` endpoint is FREE (doesn't count)
- Monitor usage via response headers

🗄️ **Database:**
- Local: `betstack_api_development`
- Heroku: `postgresql-concentric-78186`
- All historical data is preserved (no deletions)

---

## Configuration Access in Rails

```ruby
# Access configuration anywhere in Rails
OddsApi.configuration.api_key
OddsApi.configuration.base_url
OddsApi.configuration.default_region      # "us"
OddsApi.configuration.default_odds_format # "american"
OddsApi.configuration.default_markets     # ["h2h", "spreads", "totals"]
```

---

## Status: ✅ READY FOR DEVELOPMENT

Your BetStack API is fully configured and ready to start building the data ingestion layer!

**What's Working:**
- ✅ Local development environment
- ✅ Database schema
- ✅ The Odds API connection verified
- ✅ Heroku app configured
- ✅ Environment variables set (local & Heroku)
- ⏳ Heroku database provisioning (should be ready soon)

**Next:** Build the OddsApiService and start ingesting data! 🚀

