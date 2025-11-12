# Port Configuration - BetStack API

## Summary

This BetStack API has been configured to run on **port 3004** instead of the default Rails port 3000 to avoid conflicts with other Rails APIs running on the development machine.

## Changes Made

### 1. Puma Configuration (`config/puma.rb`)
- Changed default port from 3000 to 3004
- Added comment explaining the port choice

### 2. Environment Variables (`.env`)
- Added `PORT=3004` to the local environment configuration

### 3. Postman Collection (`BetStack_API.postman_collection.json`)
- Updated `base_url` variable from `http://localhost:3000` to `http://localhost:3004`
- Updated collection description to reflect port 3004
- **Also copied to:** `/Users/shawnlindsey/Documents/DEVELOPMENT/GMNY/gmny-api/BetStack_API.postman_collection.json`

### 4. Documentation Updates
- Updated `LOCAL_SETUP_COMPLETE.md` with port 3004 references
- Updated `.cursorrules` with Development Environment section documenting port 3004

## Local Development URLs

All local API requests should now use:
- **Base URL:** `http://localhost:3004`
- **Health Check:** `http://localhost:3004/up`
- **API v1:** `http://localhost:3004/api/v1/*`

### Examples:
```bash
# Health check
curl http://localhost:3004/up

# Get sports
curl http://localhost:3004/api/v1/sports

# Get leagues
curl http://localhost:3004/api/v1/leagues
```

## Starting the Server

```bash
# Standard Rails commands work as expected
rails server        # Starts on port 3004
rails s             # Short form
rails s -p 3005     # Override to use different port
```

## Production (Heroku)

Production deployment is unaffected - Heroku still uses its own `PORT` environment variable:
- **Production URL:** `https://betstack-45ae7ff725cd.herokuapp.com`
- The `PORT=3004` in `.env` only affects local development (`.env` is gitignored)

## Postman Setup

1. Import `BetStack_API.postman_collection.json` into Postman
2. The `base_url` variable is pre-configured to `http://localhost:3004`
3. All requests will automatically use the correct port
4. Switch environments by changing the `base_url` variable:
   - Local: `http://localhost:3004` (default)
   - Production: `https://betstack-45ae7ff725cd.herokuapp.com`
   - Edge: `https://api.betstack.dev`

## Avoiding Port Conflicts

This configuration ensures the BetStack API won't conflict with other Rails applications that might be running on:
- Port 3000 (Rails default)
- Port 3001
- Port 3002
- Port 3003

If you need to run multiple instances or change the port, you can:
1. Override with command line: `rails s -p 3005`
2. Or temporarily change `PORT` in `.env` file

## Notes

- The port configuration is documented in `.cursorrules` for AI assistance
- All documentation has been updated to reflect port 3004
- The Postman collection has been synced to the GMNY API project as per the project rules

---

**Last Updated:** November 8, 2025  
**Port:** 3004  
**Environment:** Development (macOS)

