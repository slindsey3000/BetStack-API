# Deployment Guide

Complete guide to deploying the BetStack API to production (Heroku) and edge caching (Cloudflare Workers).

## Architecture Overview

```
Client → Cloudflare Worker (api.betstack.dev)
              ↓
         [KV Cache Check]
              ↓
    ┌─────────┴──────────┐
    ↓                    ↓
KV Hit (cached)    KV Miss/Write
Return <10ms      Proxy to Heroku
                  (Production API)
```

## Production API (Heroku)

### Prerequisites

- Heroku account
- Heroku CLI installed (`brew install heroku/brew/heroku`)
- Git repository with code

### Initial Setup

#### 1. Create Heroku App

```bash
heroku create betstack
# or use existing app
heroku git:remote -a betstack
```

#### 2. Add PostgreSQL Database

```bash
heroku addons:create heroku-postgresql:essential-0
```

#### 3. Set Environment Variables

```bash
heroku config:set ODDS_API_KEY=your_api_key_here
heroku config:set ODDS_API_BASE_URL=https://api.the-odds-api.com/v4
heroku config:set RAILS_ENV=production
heroku config:set CLOUDFLARE_KV_NAMESPACE_ID=your_kv_namespace_id
heroku config:set CLOUDFLARE_API_KEYS_NAMESPACE_ID=your_api_keys_namespace_id
heroku config:set CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id
heroku config:set CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
```

**Get Cloudflare values:**
- Account ID: Cloudflare Dashboard → Workers & Pages
- API Token: Cloudflare Dashboard → Profile → API Tokens (create with Workers KV permissions)
- KV Namespace IDs: Created in Cloudflare Workers setup (see below)

#### 4. Configure Dynos

```bash
# Web dyno (API server) - Free tier includes 1
heroku ps:scale web=1

# Worker dyno (background jobs) - Required for data syncing
heroku ps:scale worker=1
```

**Procfile** (already configured):
```
web: bin/rails server -p ${PORT:-5000} -e $RAILS_ENV
worker: bundle exec rake solid_queue:start
```

### Deploying

#### Push Code to Heroku

```bash
git push heroku main
```

This will:
- Build the app
- Install dependencies
- Precompile assets (none in API mode)
- Restart dynos

#### Run Migrations

```bash
heroku run rails db:migrate
```

#### Seed Default User

```bash
heroku run rails db:seed
```

#### Load Sports Data

```bash
heroku run rake odds:seed
```

### Verification

```bash
# Check app status
heroku ps

# View logs
heroku logs --tail

# Test API
curl https://betstack-45ae7ff725cd.herokuapp.com/up
# Should return: "OK"

# Test with API key
curl -H "X-API-Key: 476d6f6e657961707032303234626574737461636b6170690000000000000000" \
  https://betstack-45ae7ff725cd.herokuapp.com/api/v1/events
```

## Edge Caching (Cloudflare Workers)

### Prerequisites

- Cloudflare account
- Domain or subdomain pointed to Cloudflare
- Node.js and npm installed
- Wrangler CLI (`npm install -g wrangler`)

### Setup Steps

#### 1. Create KV Namespaces

```bash
# Login to Cloudflare
wrangler login

# Create cache namespace
wrangler kv:namespace create "CACHE"
# Note the ID (e.g., eca5c52b976c4b1cb1f242e4b8b69527)

# Create API keys namespace
wrangler kv:namespace create "API_KEYS"
# Note the ID (e.g., f9d653b5dbaf46f2b83cef2c1bb9c628)
```

#### 2. Configure Worker

Edit `cloudflare-worker/wrangler.toml`:

```toml
name = "betstack-api"
main = "src/index.js"
compatibility_date = "2024-01-01"

[[kv_namespaces]]
binding = "CACHE"
id = "YOUR_CACHE_NAMESPACE_ID"

[[kv_namespaces]]
binding = "API_KEYS"
id = "YOUR_API_KEYS_NAMESPACE_ID"

[env.production]
routes = [
  { pattern = "api.betstack.dev/*", zone_name = "betstack.dev" }
]
```

#### 3. Deploy Worker

```bash
cd cloudflare-worker
npm install
npx wrangler deploy
```

#### 4. Configure DNS

In Cloudflare Dashboard:
1. Go to DNS settings for your domain
2. Add a CNAME record:
   - **Name:** `api`
   - **Target:** `betstack-45ae7ff725cd.herokuapp.com`
   - **Proxy status:** Proxied (orange cloud)

#### 5. Sync Data to Edge

From Heroku production, trigger cache sync:

```bash
heroku run "rails runner 'SyncCloudflareCacheCriticalJob.perform_now'"
heroku run "rails runner 'SyncCloudflareCacheStaticJob.perform_now'"
```

Or wait for automatic sync (runs every 2 minutes for critical, 30 minutes for static).

### Verification

```bash
# Test edge endpoint
curl https://api.betstack.dev/api/v1/events

# Check cache headers
curl -I https://api.betstack.dev/api/v1/events
# Look for: X-Cache: HIT

# Test with API key
curl -H "X-API-Key: 476d6f6e657961707032303234626574737461636b6170690000000000000000" \
  https://api.betstack.dev/api/v1/events
```

## Background Jobs Configuration

Background jobs are configured in `config/recurring.yml` and run automatically on the worker dyno.

### Jobs Schedule

- **Smart Scheduler:** Every minute (intelligently queues odds/results syncs)
- **Sports Sync:** Daily at 6am UTC
- **Cloudflare Cache Sync (Critical):** Every 2 minutes
- **Cloudflare Cache Sync (Static):** Every 30 minutes
- **Usage Log Cleanup:** Daily at 3am UTC
- **Solid Queue Cleanup:** Hourly

### Manual Job Triggers

```bash
# Sync odds for all leagues
heroku run "rails runner 'SyncAllOddsJob.perform_now'"

# Sync odds for specific league
heroku run "rails runner \"SyncLeagueOddsJob.perform_now('basketball_nba')\""

# Sync results/scores
heroku run "rails runner 'SyncScoresJob.perform_now'"

# Sync Cloudflare cache
heroku run "rails runner 'SyncCloudflareCacheCriticalJob.perform_now'"

# Run smart scheduler manually
heroku run "rails runner 'SmartSchedulerJob.perform_now'"
```

## Monitoring

### Heroku

```bash
# View logs
heroku logs --tail

# Filter for errors
heroku logs --tail | grep ERROR

# Filter for specific jobs
heroku logs --tail | grep "SmartSchedulerJob"

# Check dyno status
heroku ps

# View metrics
heroku open
# Navigate to Metrics tab
```

### Cloudflare

1. Go to Workers & Pages in Cloudflare Dashboard
2. Select `betstack-api` worker
3. View metrics:
   - Requests per second
   - Errors
   - CPU time
   - Cache hit rate

### API Usage Dashboard

Monitor external API usage:
- **URL:** https://betstack-45ae7ff725cd.herokuapp.com/usage
- Shows daily/monthly request counts
- League breakdown
- 90-day history

## Scaling

### Increase Worker Dynos

```bash
# More concurrent job processing
heroku ps:scale worker=2
```

### Upgrade Database

```bash
# For more connections and storage
heroku addons:upgrade heroku-postgresql:standard-0
```

### Optimize Cache TTL

Edit Cloudflare Worker settings to adjust cache duration (currently 2 minutes).

## Rollback

If a deployment has issues:

```bash
# View recent releases
heroku releases

# Rollback to previous version
heroku rollback v50
```

## Environment Variables Reference

### Required
- `ODDS_API_KEY` - External API key
- `ODDS_API_BASE_URL` - External API base URL
- `RAILS_ENV` - Set to `production`
- `DATABASE_URL` - Auto-set by Heroku PostgreSQL addon

### Cloudflare (Required for Edge)
- `CLOUDFLARE_ACCOUNT_ID` - Cloudflare account ID
- `CLOUDFLARE_API_TOKEN` - API token with KV permissions
- `CLOUDFLARE_KV_NAMESPACE_ID` - Cache namespace ID
- `CLOUDFLARE_API_KEYS_NAMESPACE_ID` - API keys namespace ID

### Optional
- `PORT` - Server port (auto-set by Heroku)
- `RAILS_MAX_THREADS` - Puma thread count (default: 5)

## Troubleshooting

### Worker Dyno Not Running
```bash
heroku ps:scale worker=1
heroku restart worker
```

### Jobs Not Running
```bash
# Check Solid Queue status
heroku run rails console
> SolidQueue::Job.count
> SolidQueue::Job.where(finished_at: nil).count
```

### Cache Not Updating
```bash
# Manually trigger cache sync
heroku run "rails runner 'SyncCloudflareCacheCriticalJob.perform_now'"

# Check Cloudflare KV namespace has data
wrangler kv:key list --namespace-id YOUR_NAMESPACE_ID
```

### API Quota Exceeded
Check usage dashboard and increase quota with external API provider, or reduce sync frequency in `config/recurring.yml`.

## Continuous Deployment

For automatic deployments on every push to main:

```bash
# Connect to GitHub
heroku plugins:install heroku-repo
heroku repo:reset -a betstack

# Enable GitHub integration in Heroku Dashboard
# Settings → Deployment → GitHub → Connect to repository
# Enable "Automatic deploys" from main branch
```

## Next Steps

- Set up monitoring and alerting (Heroku add-ons like Papertrail, Sentry)
- Configure custom domain for production API
- Set up staging environment for testing before production
- Implement CI/CD pipeline (GitHub Actions)

