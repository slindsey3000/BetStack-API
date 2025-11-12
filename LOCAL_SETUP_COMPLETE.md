# 🎉 BetStack API - Local Setup Complete on New MacBook!

**Setup Date:** November 8, 2025  
**Location:** `/Users/shawnlindsey/Documents/DEVELOPMENT/BetStack/betstack_api`

---

## ✅ Setup Summary

All local development environment setup is complete and verified!

### What Was Configured:

1. **✅ Environment Variables** - `.env` file created with:
   - `ODDS_API_KEY` - Your The Odds API key
   - `ODDS_API_BASE_URL` - API base URL
   - `RAILS_ENV=development`

2. **✅ Ruby Dependencies** - All gems installed via `bundle install`
   - Rails 8.0.4
   - PostgreSQL adapter (pg gem)
   - Faraday for HTTP requests
   - Solid Queue, Solid Cache, Solid Cable
   - All other dependencies

3. **✅ PostgreSQL Databases Created**
   - `betstack_api_development` - Local development database
   - `betstack_api_test` - Test database

4. **✅ Database Migrations** - All 8 migrations applied:
   - Create sports
   - Create leagues
   - Create teams
   - Create events
   - Create bookmakers
   - Create lines
   - Create results
   - Create users

5. **✅ API Connection Verified**
   - Successfully connected to The Odds API
   - Retrieved 70 active sports
   - API Status: 415 requests used, 85 remaining
   - Test script (`test_odds_api.rb`) working perfectly

6. **✅ Rails Application**
   - All routes configured and accessible
   - Database connection verified
   - Ready to start server

---

## 🚀 Quick Start Commands

### Start the Rails Server
```bash
rails server
# or
rails s
```

Server will be available at: `http://localhost:3004`

**Note:** This project uses port 3004 to avoid conflicts with other Rails APIs on the development machine.

### Open Rails Console
```bash
rails console
# or
rails c
```

### Check API Endpoints
Your API endpoints are available at `/api/v1/`:
- GET `/api/v1/sports` - List all sports
- GET `/api/v1/leagues` - List all leagues
- GET `/api/v1/events` - List all events
- GET `/api/v1/lines` - List all odds/lines
- GET `/api/v1/results` - List all results
- GET `/api/v1/teams` - List all teams
- GET `/api/v1/bookmakers` - List all bookmakers

Test the health check endpoint:
```bash
curl http://localhost:3004/up
```

---

## 📊 Current Database Status

**Development Database:** `betstack_api_development`

Current counts (empty - fresh setup):
- Sports: 0
- Leagues: 0
- Events: 0
- Teams: 0
- Lines: 0
- Results: 0
- Bookmakers: 0

---

## 🔄 Data Syncing

Your project has several sync jobs ready to populate data:

### Sync Sports
```bash
# In Rails console
SyncSportsJob.perform_now

# Or via rake task
rails odds:sync_sports
```

### Sync League Odds (e.g., NFL)
```bash
# In Rails console
SyncLeagueOddsJob.perform_now('americanfootball_nfl')

# Or via rake task
rails odds:sync_league[americanfootball_nfl]
```

### Sync All Major Leagues
```bash
rails odds:sync
```

### Sync Scores
```bash
rails odds:sync_scores[americanfootball_nfl]
```

---

## 🎯 Console Helper Commands

Your project has convenient console helpers (see `CONSOLE_COMMANDS.md`):

```ruby
# Quick shortcuts for common operations
nfl_lines           # Get NFL lines
nba_lines           # Get NBA lines
refresh_nfl         # Refresh NFL odds
refresh_all_odds    # Refresh all major leagues
refresh_nfl_results # Refresh NFL scores
```

---

## 🔐 Environment Configuration

**Local (.env file):**
```
ODDS_API_KEY=9e998c3bca7eb84b2478a3741c6326a6
ODDS_API_BASE_URL=https://api.the-odds-api.com/v4
RAILS_ENV=development
```

**Production (Heroku):**
- App Name: `betstack`
- URL: https://betstack-45ae7ff725cd.herokuapp.com/
- Environment variables are already configured on Heroku
- Production should be running fine (as you mentioned)

---

## 📦 Heroku Commands Reference

### View Production Config
```bash
heroku config -a betstack
```

### View Production Logs
```bash
heroku logs --tail -a betstack
```

### Run Rails Console on Production
```bash
heroku run rails console -a betstack
```

### Run Migrations on Production
```bash
heroku run rails db:migrate -a betstack
```

### Check Production Database
```bash
heroku pg:info -a betstack
```

### Deploy to Production
```bash
git push heroku main
```

---

## 🔧 Useful Rails Commands

### Database
```bash
rails db:migrate          # Run pending migrations
rails db:migrate:status   # Check migration status
rails db:rollback         # Rollback last migration
rails db:reset            # Drop, create, migrate, seed
rails db:seed             # Run seeds
```

### Background Jobs
```bash
rails jobs:work           # Process background jobs
```

### Testing
```bash
rails test                # Run all tests
rails test:models         # Run model tests
rails test:controllers    # Run controller tests
```

---

## 📁 Important Files & Directories

- **`.env`** - Local environment variables (NOT in git)
- **`config/initializers/odds_api.rb`** - API configuration
- **`app/services/`** - Business logic (OddsApiClient, OddsDataIngester, etc.)
- **`app/jobs/`** - Background jobs for syncing data
- **`app/controllers/api/v1/`** - API endpoints
- **`app/models/`** - Database models
- **`BetStack_API.postman_collection.json`** - API testing collection

---

## 📖 Documentation Files

Available documentation in the repo:
- `README.md` - Main readme (template)
- `SETUP_COMPLETE.md` - Original setup from other MacBook
- `CONSOLE_COMMANDS.md` - Console helper reference
- `API_ENDPOINTS.md` - API documentation
- `POSTMAN_GUIDE.md` - Postman collection guide
- `SYNC_SCHEDULE.md` - Data sync scheduling info
- `CLOUDFLARE_EDGE_SETUP.md` - Cloudflare CDN setup
- `DATA_INGESTION_COMPLETE.md` - Data ingestion documentation
- `LEAGUE_OPTIMIZATION.md` - Performance optimization notes
- `WORKER_SETUP.md` - Background worker setup

---

## ⚡ Next Steps

### 1. Start the Server
```bash
rails server
```

### 2. Sync Initial Data
```bash
rails console
```
Then in console:
```ruby
SyncSportsJob.perform_now  # Load sports and leagues
refresh_nfl                # Load NFL odds
```

### 3. Test API Endpoints
Visit or use curl/Postman:
- http://localhost:3004/api/v1/sports
- http://localhost:3004/api/v1/leagues
- http://localhost:3004/api/v1/events

### 4. Review Postman Collection
Open `BetStack_API.postman_collection.json` in Postman to test all endpoints.

---

## 🎛️ System Info

**Ruby Version:** 3.3.6 (via rbenv)  
**Rails Version:** 8.0.4  
**PostgreSQL:** 16 (via Homebrew)  
**OS:** macOS (darwin 24.6.0)

---

## 🔗 Important URLs

**Local Development:**
- API: http://localhost:3004
- Health Check: http://localhost:3004/up

**Production (Heroku):**
- API: https://betstack-45ae7ff725cd.herokuapp.com
- Health Check: https://betstack-45ae7ff725cd.herokuapp.com/up

**External APIs:**
- The Odds API: https://api.the-odds-api.com/v4
- API Docs: https://the-odds-api.com/

---

## 💡 Tips

1. **Always check API quota** before syncing:
   ```ruby
   ruby test_odds_api.rb
   ```

2. **Use console helpers** for quick operations:
   ```ruby
   rails c
   nfl_lines  # Much easier than writing queries!
   ```

3. **Monitor background jobs** in development:
   ```ruby
   rails jobs:work
   ```

4. **Check logs** when debugging:
   ```bash
   tail -f log/development.log
   ```

5. **The `.env` file** is gitignored for security - never commit it!

---

## ✅ Status: READY FOR DEVELOPMENT! 🚀

Your local environment is fully configured and ready to use. You can now:
- Start the Rails server
- Run background jobs
- Test API endpoints
- Sync data from The Odds API
- Deploy to Heroku when ready

**Everything is working perfectly on your new MacBook!** 🎉

---

*Last updated: November 8, 2025*

