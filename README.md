# BetStack API

A Ruby on Rails 8 API that serves as the central data hub for sports and sports betting information. Ingests live odds and results from external sports data providers and exposes them through fast, well-designed RESTful endpoints with global edge caching.

## 🚀 Quick Start

### Live API
- **Production:** `https://betstack-45ae7ff725cd.herokuapp.com/api/v1`
- **Edge (Cloudflare):** `https://api.betstack.dev/api/v1` (sub-10ms global response times)

### Example Request
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/events?league_key=basketball_nba"
```

## ⚡ Key Features

### Smart Data Syncing
- **Intelligent Scheduler:** Dynamically adjusts sync frequency based on actual game schedules
- **Frequency Tiers:** 
  - Every 30 min (baseline)
  - Every 10 min (within 2 hours of game)
  - Every 2 min (within 10 minutes of game start)
- **Live Results:** Scores updated every 2 minutes during games
- **Target:** ~17,000 API requests/month, optimized for 100K quota

### Global Edge Caching
- **Cloudflare Workers + KV:** API responses cached at 300+ global locations
- **Sub-10ms Response Times:** Blazing fast for end users worldwide
- **Auto-Sync:** Cache refreshed every 2 minutes from production
- **Smart Caching:** Critical endpoints (lines, events, results) vs static (sports, leagues)

### Major North American Leagues
Focused on the 6 most popular leagues:
- 🏀 **NBA** - National Basketball Association
- 🏈 **NFL** - National Football League  
- 🏒 **NHL** - National Hockey League
- ⚾ **MLB** - Major League Baseball
- 🏈 **NCAAF** - College Football
- 🏀 **NCAAB** - College Basketball

### BetStack Consensus Lines
- Aggregates odds from multiple bookmakers
- Provides normalized "BetStack" consensus line
- Supports individual bookmaker filtering (DraftKings, FanDuel, etc.)

## 📚 Documentation

- **[API Endpoints Reference](docs/api/endpoints.md)** - Complete endpoint documentation
- **[Local Setup Guide](docs/setup/local-setup.md)** - Get started developing locally
- **[Deployment Guide](docs/setup/deployment.md)** - Deploy to Heroku and Cloudflare
- **[Postman Testing Guide](docs/setup/postman-testing.md)** - Test the API with Postman
- **[Console Commands](docs/development/console-commands.md)** - Useful Rails console helpers

## 🛠️ Tech Stack

- **Ruby on Rails 8.0** - Modern Rails with built-in async jobs
- **PostgreSQL** - Highly relational database design
- **Solid Queue** - Background jobs for data syncing (Rails 8 built-in)
- **Solid Cache** - Application caching (Rails 8 built-in)
- **Faraday** - HTTP client for external API requests
- **Cloudflare Workers + KV** - Global edge caching and API key validation
- **Heroku** - Production hosting with worker dynos

## 🗄️ Database Design

Highly referential, object-oriented structure:
- **Sports** - Top-level sports (Basketball, Football, etc.)
- **Leagues** - Competitions within sports (NBA, NFL, etc.)
- **Teams** - Individual teams with normalized names
- **Events** - Games/matches with scheduled times
- **Lines** - Betting odds (moneyline, spread, totals)
- **Results** - Live and final scores
- **Bookmakers** - Sportsbooks providing odds
- **Users** - API key authentication

## 🎯 API Design Principles

- **RESTful** - Standard HTTP methods and status codes
- **Versioned** - `/api/v1/` namespace for backward compatibility
- **No Pagination** - Return full datasets for simplicity
- **Clean JSON** - No metadata wrappers, just data arrays
- **Filtering** - Rich query parameters for precise data requests
- **Fast** - Edge caching for sub-10ms global response times

## 📊 Monitoring

- **API Usage Dashboard:** `https://betstack-45ae7ff725cd.herokuapp.com/usage`
  - Real-time request tracking
  - Daily/monthly usage statistics
  - League-level breakdown
  - 90-day history

## 🔐 Authentication

All API requests require an `X-API-Key` header:
```bash
curl -H "X-API-Key: YOUR_KEY" https://api.betstack.dev/api/v1/events
```

API keys are validated at the edge (Cloudflare) for maximum performance.

## 🚦 Rate Limiting

- **Production:** 1,000 requests/day per API key
- **Edge:** 100 requests/minute per API key or IP address
- Rate limit headers included in all responses

## 🔗 Related Projects

- **GMNY API Client:** Consumes BetStack API for game day predictions
- **Postman Collection:** `BetStack_API.postman_collection.json`

## 📄 License

Proprietary - All rights reserved
