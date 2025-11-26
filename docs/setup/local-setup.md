# Local Development Setup

Complete guide to setting up the BetStack API on your local development machine.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Ruby 3.3.9** or later
- **PostgreSQL 14+** (with running server)
- **Bundler** (`gem install bundler`)
- **Git**
- **Heroku CLI** (optional, for production access)

## Setup Steps

### 1. Clone the Repository

```bash
git clone https://github.com/slindsey3000/BetStack-API.git
cd betstack_api
```

### 2. Install Dependencies

```bash
bundle install
```

This installs all required gems including:
- Rails 8.0.4
- PostgreSQL adapter (pg)
- Faraday (HTTP client)
- Solid Queue, Solid Cache, Solid Cable
- All other dependencies

### 3. Create Environment Variables

Create a `.env` file in the project root:

```bash
# .env
ODDS_API_KEY=your_api_key_here
ODDS_API_BASE_URL=https://api.the-odds-api.com/v4
RAILS_ENV=development
PORT=3004
```

**Get an API key:**
1. Sign up at https://the-odds-api.com/
2. Copy your API key from the dashboard
3. Paste it into the `.env` file

**Note:** This project uses **port 3004** to avoid conflicts with other Rails APIs.

### 4. Create Databases

```bash
rails db:create
```

This creates:
- `betstack_api_development` - Development database
- `betstack_api_test` - Test database

### 5. Run Migrations

```bash
rails db:migrate
```

This creates all database tables:
- `sports` - Top-level sports categories
- `leagues` - Leagues/competitions within sports
- `teams` - Individual teams
- `events` - Games/matches
- `bookmakers` - Sportsbooks
- `lines` - Betting odds
- `results` - Game scores
- `users` - API key authentication
- `api_usage_logs` - API usage tracking
- `solid_queue_*` - Background job tables

### 6. Seed Default Data

```bash
rails db:seed
```

This creates a default **GMoneyApp** user with a known API key for testing:
- Email: `gmoneyapp@betstack.dev`
- API Key: `476d6f6e657961707032303234626574737461636b6170690000000000000000`

### 7. Seed Sports Data (Optional)

Load real sports, leagues, teams, and odds from the external API:

```bash
rake odds:seed
```

This will:
- Fetch all sports and leagues
- Create the 6 major North American leagues (NBA, NFL, NHL, MLB, NCAAF, NCAAB)
- Load teams for each league
- Fetch current betting lines

**Note:** This uses your API quota (approximately 10-15 requests).

## Running the Server

### Start Rails Server

```bash
rails server
# or
rails s
```

The server will be available at: **http://localhost:3004**

### Verify It's Running

```bash
curl http://localhost:3004/up
# Should return: "OK"
```

### Test an API Endpoint

```bash
curl -H "X-API-Key: 476d6f6e657961707032303234626574737461636b6170690000000000000000" \
  http://localhost:3004/api/v1/events
```

## Background Jobs (Optional)

If you want to test background jobs locally (data syncing):

```bash
# In a separate terminal window
rails solid_queue:start
```

This starts the job worker to process:
- Odds syncing (smart scheduler)
- Results syncing
- Cloudflare cache syncing
- API usage log cleanup

## Rails Console

Access the Rails console for debugging and testing:

```bash
rails console
# or
rails c
```

See **[Console Commands](../development/console-commands.md)** for useful helper methods.

## Rake Tasks

### Sync Odds for All Major Leagues
```bash
rake odds:sync
```

### Sync Odds for Specific League
```bash
rake odds:sync_league[basketball_nba]
```

### Sync Scores/Results
```bash
rake odds:sync_scores
```

### View Database Statistics
```bash
rake odds:stats
```

## Common Issues

### Port Already in Use
If port 3004 is already in use, you can specify a different port:
```bash
PORT=3005 rails server
```

### PostgreSQL Not Running
```bash
# macOS (Homebrew)
brew services start postgresql@14

# Linux
sudo service postgresql start
```

### Missing API Key
If you see "API key is required" errors:
1. Check that `.env` file exists in project root
2. Verify `ODDS_API_KEY` is set
3. Restart the Rails server to load environment variables

### Database Connection Error
Ensure PostgreSQL is running and accepting connections:
```bash
psql -U postgres -c "SELECT version();"
```

If you need to reset the database:
```bash
rails db:drop db:create db:migrate db:seed
```

## Next Steps

- **[API Endpoints](../api/endpoints.md)** - Explore available API endpoints
- **[Postman Testing](postman-testing.md)** - Test the API with Postman collection
- **[Deployment Guide](deployment.md)** - Deploy to production (Heroku + Cloudflare)
- **[Console Commands](../development/console-commands.md)** - Useful Rails console helpers

## Development Workflow

1. Make code changes
2. Test locally at `http://localhost:3004`
3. Use Postman collection for API testing
4. Check logs: `tail -f log/development.log`
5. Commit changes: `git add . && git commit -m "description"`
6. Push to GitHub: `git push origin main`
7. Deploy to Heroku: `git push heroku main`

