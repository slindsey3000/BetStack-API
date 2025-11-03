# Cloudflare Edge Caching Setup

This document describes the Cloudflare Workers + KV edge caching implementation for the BetStack API.

## Architecture Overview

```
Client Request → Cloudflare Worker (api.betstack.dev)
                      ↓
                 [Check KV Cache]
                      ↓
        ┌─────────────┴─────────────┐
        ↓                           ↓
   KV Hit (cached)            KV Miss or Write
   Return instantly           Proxy to Heroku
   (sub-10ms)                 (fallback)
```

### How It Works

1. **Edge Caching**: All GET requests to `/api/v1/*` are cached at Cloudflare's 300+ global locations
2. **Automatic Sync**: Heroku background job (`SyncCloudflareCacheJob`) pushes fresh data to KV every minute
3. **Origin Fallback**: Cache misses and write operations (POST/PUT) proxy directly to Heroku
4. **API Key Validation**: Valid API keys are synced to edge, validated without hitting origin
5. **Rate Limiting**: 100 requests/minute per API key or IP address
6. **User Endpoints**: `/api/v1/users` always bypass cache for security

## Configuration

### Cloudflare Resources

- **Account ID**: `bae9989b45be5e3c222499cf37a7d305`
- **Worker**: `betstack-api` deployed to `api.betstack.dev/*`
- **KV Namespaces**:
  - **CACHE** (`eca5c52b976c4b1cb1f242e4b8b69527`): Stores endpoint responses
  - **API_KEYS** (`f9d653b5dbaf46f2b83cef2c1bb9c628`): Stores valid API keys

### DNS Configuration

The domain `betstack.dev` is managed through Cloudflare DNS:

- **Root Domain**: `betstack.dev` → CNAME to Vercel (your website)
- **API Subdomain**: `api.betstack.dev` → CNAME to Heroku with Proxy (orange cloud) enabled

The Worker intercepts all requests to `api.betstack.dev/*` before they reach Heroku.

### Environment Variables

Required environment variables (set locally in `.env` and on Heroku):

```bash
CLOUDFLARE_ACCOUNT_ID=bae9989b45be5e3c222499cf37a7d305
CLOUDFLARE_KV_NAMESPACE_ID=eca5c52b976c4b1cb1f242e4b8b69527
CLOUDFLARE_API_KEYS_NAMESPACE_ID=f9d653b5dbaf46f2b83cef2c1bb9c628
CLOUDFLARE_API_TOKEN=<your_kv_update_token>
```

## Cached Endpoints

The following endpoints are cached at the edge (refreshed every minute):

### General Endpoints
- `/api/v1/sports` - All sports
- `/api/v1/leagues` - All leagues
- `/api/v1/events` - Upcoming/live events
- `/api/v1/lines` - BetStack consensus lines (major leagues only)
- `/api/v1/lines/incomplete` - Lines with missing data
- `/api/v1/results` - Recent game results (last 3 days)
- `/api/v1/teams` - All teams
- `/api/v1/bookmakers` - All bookmakers

### League-Specific Endpoints
For each major North American league (NBA, NFL, NHL, MLB, NCAAF, NCAAB):
- `/api/v1/lines?league_key={league}` - Lines for specific league
- `/api/v1/events?league_key={league}` - Events for specific league

**Total**: 20+ endpoints cached

## Sync Schedule

### Cloudflare Cache Sync
- **Frequency**: Every minute
- **Job**: `SyncCloudflareCacheJob`
- **Duration**: ~2-3 seconds
- **Operations**:
  - Generates fresh JSON for all endpoints
  - Bulk uploads to Cloudflare KV
  - Syncs valid API keys for edge validation

### Odds & Results Sync
- **Odds**: 2x daily (12pm UTC, 8pm UTC)
- **Results**: 2x daily (10pm UTC, 3am UTC)
- These update the Heroku database, then Cloudflare cache picks up changes every minute

## Performance

### Response Times
- **Cache HIT**: 5-15ms (served from nearest Cloudflare edge location)
- **Cache MISS**: 200-500ms (proxied to Heroku, then cached)
- **User endpoints**: 200-500ms (always proxied, never cached)

### Cache Headers
Responses include headers indicating cache status:
- `X-Cache: HIT` - Served from edge cache
- `X-Cache: MISS` - Served from origin, now cached
- `X-Cache: BYPASS` - Proxied to origin (users, writes)
- `X-Cache-Status` - Detailed status message

### Cost & Limits
- **Tier**: Cloudflare Free Plan
- **Request Limit**: 100,000 requests/day
- **Rate Limiting**: 100 requests/minute per API key/IP
- **KV Storage**: Unlimited keys (generous free tier)
- **Bandwidth**: Unlimited

## Deployment

### Worker Deployment

```bash
cd cloudflare-worker
npx wrangler deploy
```

### Heroku Deployment

Changes to sync services automatically deploy:

```bash
git push heroku main
```

The worker dyno will pick up the new recurring job configuration.

## Testing

### Test Edge Caching

```bash
# First request (cache miss)
curl -I https://api.betstack.dev/api/v1/lines
# Look for: X-Cache: MISS

# Second request (cache hit)
curl -I https://api.betstack.dev/api/v1/lines
# Look for: X-Cache: HIT

# Check response time difference
time curl -s https://api.betstack.dev/api/v1/lines > /dev/null
```

### Test API Key Validation

```bash
# With valid API key
curl -H "X-API-Key: YOUR_KEY" https://api.betstack.dev/api/v1/lines

# With invalid API key
curl -H "X-API-Key: invalid" https://api.betstack.dev/api/v1/lines
# Returns: 401 Unauthorized
```

### Test Rate Limiting

```bash
# Send 101 requests quickly
for i in {1..101}; do 
  curl -s https://api.betstack.dev/api/v1/lines > /dev/null
  echo "Request $i"
done

# 101st request should return 429 Rate Limit Exceeded
```

### Manual Sync Test

```bash
# Trigger manual sync on Heroku
heroku run rails runner "SyncCloudflareCacheJob.perform_now" --app betstack

# Check logs
heroku logs --tail --app betstack | grep Cloudflare
```

## Monitoring

### Cloudflare Dashboard

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select `betstack.dev` zone
3. Navigate to **Workers & Pages** → `betstack-api`
4. View metrics:
   - Requests per second
   - Error rates
   - CPU time
   - Success rate

### Heroku Logs

```bash
# Watch sync logs
heroku logs --tail --app betstack --ps worker

# Search for Cloudflare sync
heroku logs --app betstack | grep "Cloudflare"
```

### KV Storage Dashboard

1. Cloudflare Dashboard → **Workers & Pages** → KV
2. View namespaces:
   - `betstack-api-CACHE` - Endpoint responses
   - `betstack-api-API_KEYS` - Valid API keys
3. Click namespace to browse keys and values

## Troubleshooting

### Cache Not Updating

**Problem**: Old data being served from edge

**Solution**:
1. Check Heroku worker is running: `heroku ps --app betstack`
2. Check sync job logs: `heroku logs --tail --app betstack | grep SyncCloudflareCacheJob`
3. Manually trigger sync: `heroku run rails runner "SyncCloudflareCacheJob.perform_now" --app betstack`

### Worker Not Intercepting Requests

**Problem**: Requests going directly to Heroku

**Solution**:
1. Verify DNS: `dig api.betstack.dev` (should show Cloudflare IPs)
2. Check Worker route in dashboard (should be `api.betstack.dev/*`)
3. Ensure DNS proxy status is enabled (orange cloud) for `api.betstack.dev`

### API Key Validation Failing

**Problem**: Valid keys returning 401

**Solution**:
1. Check API keys are synced: View `API_KEYS` namespace in Cloudflare dashboard
2. Verify user is active and key valid: `heroku run rails console --app betstack`
   ```ruby
   User.valid.pluck(:api_key)
   ```
3. Manually trigger key sync: `heroku run rails runner "CloudflareCacheSyncer.new.sync_api_keys" --app betstack`

### Rate Limit Too Strict

**Problem**: Legitimate users hitting rate limits

**Solution**:
Edit `cloudflare-worker/src/index.js`, increase limit:
```javascript
if (requests && parseInt(requests) > 1000) { // Increase from 100 to 1000
```
Then redeploy: `cd cloudflare-worker && npx wrangler deploy`

## Adding New Cached Endpoints

To add a new endpoint to edge caching:

1. **Add endpoint to sync list** in `app/services/cloudflare_cache_syncer.rb`:
   ```ruby
   def build_endpoint_list
     endpoints = [
       # ... existing endpoints ...
       '/api/v1/your_new_endpoint'  # Add here
     ]
   end
   ```

2. **Add response generation** in same file:
   ```ruby
   def generate_endpoint_response(endpoint)
     case path
     # ... existing cases ...
     when '/api/v1/your_new_endpoint'
       YourModel.all.map(&:api_json)
     end
   end
   ```

3. **Deploy**: `git push heroku main`

4. **Test**: Sync runs every minute, or trigger manually

## Security

- **API Keys**: Validated at edge, no origin hit needed
- **User Data**: Never cached, always proxied to origin
- **Rate Limiting**: Prevents abuse (100 req/min per key/IP)
- **CORS**: Fully enabled for cross-origin requests
- **Environment Variables**: Stored securely in Heroku and Cloudflare

## Future Enhancements

1. **Cache Invalidation**: Add webhook to invalidate specific keys on demand
2. **Analytics**: Track cache hit rates, popular endpoints
3. **Regional Optimization**: Pre-warm cache in high-traffic regions
4. **Conditional Requests**: Support ETags and If-Modified-Since headers
5. **Compression**: Enable Brotli compression for responses
6. **Upgrade Plan**: Move to Workers Paid ($5/mo) for 10M requests/day

## Support

- **Cloudflare Docs**: https://developers.cloudflare.com/workers/
- **KV Documentation**: https://developers.cloudflare.com/kv/
- **Wrangler CLI**: https://developers.cloudflare.com/workers/wrangler/

---

**Last Updated**: November 3, 2025  
**Version**: 1.0  
**Status**: ✅ Production Ready

