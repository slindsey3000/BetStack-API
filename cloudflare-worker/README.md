# BetStack API Cloudflare Worker

This Cloudflare Worker provides edge caching for the BetStack API, serving requests from 300+ global locations with sub-10ms response times.

## Architecture

- **Edge Caching**: GET requests are served from Cloudflare KV storage
- **Origin Fallback**: Cache misses and write operations proxy to Heroku
- **API Key Validation**: Validated at the edge (no origin hit needed)
- **Rate Limiting**: 100 requests/minute per API key or IP address
- **CORS Support**: Full CORS headers for cross-origin requests

## KV Namespaces

- **CACHE** (`eca5c52b976c4b1cb1f242e4b8b69527`): Stores API endpoint responses
- **API_KEYS** (`f9d653b5dbaf46f2b83cef2c1bb9c628`): Stores valid API keys

## Deployment

```bash
# Install dependencies
npm install

# Deploy to production
npx wrangler deploy

# Test locally
npx wrangler dev
```

## Routes

- `api.betstack.dev/*` - All API traffic goes through this worker

## Cache Strategy

- **Cached endpoints**: All GET requests to `/api/v1/*` except `/api/v1/users`
- **Uncached endpoints**: `/api/v1/users` (always proxied to origin)
- **Cache TTL**: 2 minutes (refreshed every minute by Heroku job)
- **Rate limit TTL**: 1 minute (resets every minute)

## Response Headers

- `X-Cache: HIT` - Served from edge cache
- `X-Cache: MISS` - Served from origin, now cached
- `X-Cache: BYPASS` - Always proxied to origin (users, writes)
- `X-Cache-Status` - Detailed cache status

## Testing

```bash
# Test endpoint
curl https://api.betstack.dev/api/v1/lines

# Test with API key
curl -H "X-API-Key: YOUR_KEY" https://api.betstack.dev/api/v1/lines

# Check cache status
curl -I https://api.betstack.dev/api/v1/lines

# Test rate limiting (run 101 times quickly)
for i in {1..101}; do curl -s https://api.betstack.dev/api/v1/lines > /dev/null; done
curl https://api.betstack.dev/api/v1/lines  # Should return 429
```

## Monitoring

View analytics in Cloudflare Dashboard:
1. Go to Workers & Pages
2. Select `betstack-api`
3. View metrics (requests, errors, CPU time)

## Cost

- **Free tier**: 100,000 requests/day
- **Paid tier**: $5/month for 10M requests
- Current configuration stays within free tier limits

