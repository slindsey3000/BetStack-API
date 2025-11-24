# BetStack API - Complete Endpoint Reference

**Version:** v1  
**Last Updated:** November 22, 2025

---

## 📍 Base URLs

| Environment | URL | Authentication Required |
|------------|-----|------------------------|
| **Production** | `https://betstack-45ae7ff725cd.herokuapp.com` | Yes (X-API-Key header) |
| **Edge (Cloudflare)** | `https://api.betstack.dev` | Yes (X-API-Key header) |
| **Local Development** | `http://localhost:3004` | Yes (X-API-Key header) |

---

## 🔑 Authentication

All API endpoints require authentication via the `X-API-Key` header:

```http
X-API-Key: your-api-key-here
```

**Example:**
```bash
curl -H "X-API-Key: 476d6f6e657961707032303234626574737461636b6170690000000000000000" \
  https://betstack-45ae7ff725cd.herokuapp.com/api/v1/sports
```

---

## 📊 Public Endpoints (No Authentication)

### Usage Dashboard
View API usage statistics and quota monitoring.

| Endpoint | Method | Available On | Description |
|----------|--------|-------------|-------------|
| `/usage` | GET | Production Only | HTML dashboard showing daily API usage stats |
| `/usage.json` | GET | Production Only | JSON format of usage statistics |

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/usage`
- ❌ Edge: Not available (authentication required)

**Example Response (JSON):**
```json
{
  "today": 150,
  "month": 4523,
  "daily": {
    "2025-11-22": 150,
    "2025-11-21": 145
  },
  "by_league_last_30_days": {
    "basketball_nba": 2341,
    "americanfootball_nfl": 1523
  }
}
```

---

## 🏀 API v1 Endpoints

All endpoints below are prefixed with `/api/v1/`

---

## 1️⃣ Sports

Get information about available sports.

### List All Sports
```
GET /api/v1/sports
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/sports`
- ✅ Edge: `https://api.betstack.dev/api/v1/sports` (cached, synced every 30 min)

**Query Parameters:**
- `active` (optional) - Filter to only active sports. Values: `true` or `false`

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/sports?active=true"
```

**Example Response:**
```json
[
  {
    "id": 1,
    "key": "basketball_nba",
    "name": "NBA",
    "active": true,
    "group": "Basketball",
    "description": "US Basketball",
    "has_outrights": false
  }
]
```

---

### Get Single Sport
```
GET /api/v1/sports/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/sports/:id`
- ❌ Edge: Not cached (use production)

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://betstack-45ae7ff725cd.herokuapp.com/api/v1/sports/1"
```

**Example Response:**
```json
{
  "id": 1,
  "key": "basketball_nba",
  "name": "NBA",
  "active": true,
  "group": "Basketball",
  "description": "US Basketball",
  "has_outrights": false,
  "leagues_count": 1
}
```

---

## 2️⃣ Leagues

Get information about leagues within sports.

### List All Leagues
```
GET /api/v1/leagues
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/leagues`
- ✅ Edge: `https://api.betstack.dev/api/v1/leagues` (cached, synced every 30 min)

**Query Parameters:**
- `active` (optional) - Filter to only active leagues. Values: `true` or `false`
- `sport_id` (optional) - Filter by sport ID
- `north_american` (optional) - Filter to major North American leagues (NBA, NFL, NHL, MLB, NCAAF, NCAAB). Values: `true` or `false`

**Special Cached Endpoint:**
- ✅ Edge: `https://api.betstack.dev/api/v1/leagues?north_american=true` (pre-cached)

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/leagues?north_american=true"
```

**Example Response:**
```json
[
  {
    "id": 1,
    "key": "basketball_nba",
    "name": "NBA",
    "region": "US",
    "active": true,
    "has_outrights": false,
    "sport": {
      "id": 1,
      "name": "Basketball"
    }
  }
]
```

---

### Get Single League
```
GET /api/v1/leagues/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/leagues/:id`
- ❌ Edge: Not cached (use production)

**Example Response:**
```json
{
  "id": 1,
  "key": "basketball_nba",
  "name": "NBA",
  "region": "US",
  "active": true,
  "has_outrights": false,
  "sport": {
    "id": 1,
    "name": "Basketball"
  },
  "teams_count": 30,
  "upcoming_events_count": 15
}
```

---

## 3️⃣ Teams

Get information about teams.

### List All Teams
```
GET /api/v1/teams
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/teams`
- ✅ Edge: `https://api.betstack.dev/api/v1/teams` (cached, synced every 30 min)

**Query Parameters:**
- `active` (optional) - Filter to only active teams. Values: `true` or `false`
- `league_key` (optional) - Filter by league key (e.g., `basketball_nba`)

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/teams?league_key=basketball_nba"
```

**Example Response:**
```json
[
  {
    "id": 1,
    "name": "Los Angeles Lakers",
    "normalized_name": "Los Angeles Lakers",
    "active": true,
    "league": {
      "id": 1,
      "key": "basketball_nba",
      "name": "NBA"
    }
  }
]
```

---

### Get Single Team
```
GET /api/v1/teams/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/teams/:id`
- ❌ Edge: Not cached (use production)

**Example Response:**
```json
{
  "id": 1,
  "name": "Los Angeles Lakers",
  "normalized_name": "Los Angeles Lakers",
  "active": true,
  "league": {
    "id": 1,
    "key": "basketball_nba",
    "name": "NBA"
  },
  "home_events_count": 41,
  "away_events_count": 41
}
```

---

## 4️⃣ Events

Get information about games/matches.

### List All Events
```
GET /api/v1/events
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/events`
- ✅ Edge: `https://api.betstack.dev/api/v1/events` (cached, synced every 2 min)

**Query Parameters:**
- `status` (optional) - Filter by event status. Values: `upcoming`, `live`, `completed`, or leave blank for default (upcoming + live)
- `league_key` (optional) - Filter by league key (e.g., `basketball_nba`)
- `north_american` (optional) - Filter to major North American leagues. Values: `true` or `false`
- `date` (optional) - Filter by specific date (YYYY-MM-DD)

**Special Cached Endpoints:**
- ✅ Edge: `https://api.betstack.dev/api/v1/events?north_american=true` (pre-cached)
- ✅ Edge: `https://api.betstack.dev/api/v1/events?league_key=basketball_nba` (pre-cached for each major league)

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/events?league_key=basketball_nba&status=upcoming"
```

**Example Response:**
```json
[
  {
    "id": 123,
    "commence_time": "2025-11-23T00:00:00.000Z",
    "status": "upcoming",
    "completed": false,
    "league": {
      "id": 1,
      "key": "basketball_nba",
      "name": "NBA"
    },
    "home_team": {
      "id": 1,
      "name": "Los Angeles Lakers"
    },
    "away_team": {
      "id": 2,
      "name": "Boston Celtics"
    }
  }
]
```

---

### Get Single Event
```
GET /api/v1/events/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/events/:id`
- ❌ Edge: Not cached (use production)

**Example Response:**
```json
{
  "id": 123,
  "commence_time": "2025-11-23T00:00:00.000Z",
  "status": "upcoming",
  "completed": false,
  "league": {
    "id": 1,
    "key": "basketball_nba",
    "name": "NBA"
  },
  "home_team": {
    "id": 1,
    "name": "Los Angeles Lakers"
  },
  "away_team": {
    "id": 2,
    "name": "Boston Celtics"
  },
  "lines": [],
  "result": null
}
```

---

## 5️⃣ Lines (Betting Odds)

Get betting lines and odds for events.

### List All Lines
```
GET /api/v1/lines
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/lines`
- ✅ Edge: `https://api.betstack.dev/api/v1/lines` (cached, synced every 2 min)

**Query Parameters:**
- `event_id` (optional) - Filter by specific event ID
- `league_key` (optional) - Filter by league key (e.g., `basketball_nba`)
- `north_american` (optional) - Filter to major North American leagues. Values: `true` or `false`
- `bookmaker_key` (optional) - Filter by bookmaker key. Default: `betstack` (consensus lines)
- `date` (optional) - Filter by specific date (YYYY-MM-DD)

**Special Cached Endpoints:**
- ✅ Edge: `https://api.betstack.dev/api/v1/lines?north_american=true` (pre-cached)
- ✅ Edge: `https://api.betstack.dev/api/v1/lines?league_key=basketball_nba` (pre-cached for each major league)
- ✅ Edge: `https://api.betstack.dev/api/v1/lines?league_key=americanfootball_nfl` (pre-cached)
- ✅ Edge: `https://api.betstack.dev/api/v1/lines?league_key=icehockey_nhl` (pre-cached)
- ✅ Edge: `https://api.betstack.dev/api/v1/lines?league_key=baseball_mlb` (pre-cached)
- ✅ Edge: `https://api.betstack.dev/api/v1/lines?league_key=americanfootball_ncaaf` (pre-cached)
- ✅ Edge: `https://api.betstack.dev/api/v1/lines?league_key=basketball_ncaab` (pre-cached)

**Note:** Lines are filtered to only show events from the last 24 hours or upcoming events.

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/lines?league_key=basketball_nba"
```

**Example Response:**
```json
[
  {
    "id": 456,
    "event_id": 123,
    "event": {
      "id": 123,
      "commence_time": "2025-11-23T00:00:00.000Z",
      "home_team": "Los Angeles Lakers",
      "away_team": "Boston Celtics",
      "league": {
        "key": "basketball_nba",
        "name": "NBA"
      }
    },
    "bookmaker": {
      "id": 1,
      "key": "betstack",
      "name": "BetStack"
    },
    "moneyline": {
      "home": "-150",
      "away": "+130",
      "draw": null
    },
    "spread": {
      "home": {
        "point": "-3.5",
        "price": "-110"
      },
      "away": {
        "point": "+3.5",
        "price": "-110"
      }
    },
    "total": {
      "number": "225.5",
      "over": "-110",
      "under": "-110"
    },
    "last_updated": "2025-11-22T20:30:00.000Z",
    "source": "consensus"
  }
]
```

---

### Get Incomplete Lines
```
GET /api/v1/lines/incomplete
```

Returns lines that are missing one or more market types (moneyline, spread, or totals).

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/lines/incomplete`
- ✅ Edge: `https://api.betstack.dev/api/v1/lines/incomplete` (cached, synced every 2 min)

**Query Parameters:**
- `league_key` (optional) - Filter by league key
- `north_american` (optional) - Filter to major North American leagues. Values: `true` or `false`
- `bookmaker_key` (optional) - Filter by bookmaker key. Default: `betstack`

**Special Cached Endpoint:**
- ✅ Edge: `https://api.betstack.dev/api/v1/lines/incomplete?north_american=true` (pre-cached)

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/lines/incomplete?north_american=true"
```

---

## 6️⃣ Results

Get game scores and results.

### List All Results
```
GET /api/v1/results
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/results`
- ✅ Edge: `https://api.betstack.dev/api/v1/results` (cached, synced every 2 min)

**Query Parameters:**
- `league_key` (optional) - Filter by league key (e.g., `basketball_nba`)
- `north_american` (optional) - Filter to major North American leagues. Values: `true` or `false`
- `completed` (optional) - Filter to only completed games. Values: `true` or `false`

**Special Cached Endpoint:**
- ✅ Edge: `https://api.betstack.dev/api/v1/results?north_american=true` (pre-cached)

**Note:** Results are filtered to only show games from the last 7 days.

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/results?league_key=basketball_nba"
```

**Example Response:**
```json
[
  {
    "id": 789,
    "event_id": 123,
    "completed": true,
    "home_score": 105,
    "away_score": 98,
    "last_update": "2025-11-22T23:00:00.000Z",
    "event": {
      "id": 123,
      "commence_time": "2025-11-22T20:00:00.000Z",
      "home_team": "Los Angeles Lakers",
      "away_team": "Boston Celtics",
      "league": {
        "key": "basketball_nba",
        "name": "NBA"
      }
    }
  }
]
```

---

### Get Single Result
```
GET /api/v1/results/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/results/:id`
- ❌ Edge: Not cached (use production)

**Example Response:**
```json
{
  "id": 789,
  "event_id": 123,
  "completed": true,
  "home_score": 105,
  "away_score": 98,
  "last_update": "2025-11-22T23:00:00.000Z",
  "event": {
    "id": 123,
    "commence_time": "2025-11-22T20:00:00.000Z",
    "status": "completed",
    "completed": true,
    "home_team": {
      "id": 1,
      "name": "Los Angeles Lakers"
    },
    "away_team": {
      "id": 2,
      "name": "Boston Celtics"
    },
    "league": {
      "id": 1,
      "key": "basketball_nba",
      "name": "NBA"
    }
  }
}
```

---

## 7️⃣ Bookmakers

Get information about sportsbooks.

### List All Bookmakers
```
GET /api/v1/bookmakers
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/bookmakers`
- ✅ Edge: `https://api.betstack.dev/api/v1/bookmakers` (cached, synced every 30 min)

**Query Parameters:**
- `active` (optional) - Filter to only active bookmakers. Values: `true` or `false`

**Example Request:**
```bash
curl -H "X-API-Key: YOUR_KEY" \
  "https://api.betstack.dev/api/v1/bookmakers"
```

**Example Response:**
```json
[
  {
    "id": 1,
    "key": "betstack",
    "name": "BetStack",
    "active": true
  },
  {
    "id": 2,
    "key": "fanduel",
    "name": "FanDuel",
    "active": true
  }
]
```

---

### Get Single Bookmaker
```
GET /api/v1/bookmakers/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/bookmakers/:id`
- ❌ Edge: Not cached (use production)

**Example Response:**
```json
{
  "id": 1,
  "key": "betstack",
  "name": "BetStack",
  "active": true,
  "lines_count": 1500
}
```

---

## 8️⃣ Users (Admin Only)

Manage API users and keys.

### List All Users
```
GET /api/v1/users
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/users`
- ❌ Edge: Not available (proxied to production for security)

**Example Response:**
```json
[
  {
    "id": 1,
    "email": "user@example.com",
    "phone_number": "1234567890",
    "address": "123 Main St",
    "active": true,
    "start_time": "2025-01-01T00:00:00.000Z",
    "end_time": "2125-01-01T00:00:00.000Z"
  }
]
```

---

### Get Single User
```
GET /api/v1/users/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/users/:id`
- ❌ Edge: Not available (proxied to production for security)

**Note:** API key is NOT returned for security reasons.

---

### Create User
```
POST /api/v1/users
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/users`
- ❌ Edge: Not available (proxied to production for security)

**Request Body:**
```json
{
  "email": "newuser@example.com",
  "phone_number": "1234567890",
  "address": "123 Main St"
}
```

**Response:**
```json
{
  "id": 2,
  "email": "newuser@example.com",
  "phone_number": "1234567890",
  "address": "123 Main St",
  "api_key": "generated-api-key-here",
  "active": true,
  "start_time": "2025-11-22T00:00:00.000Z",
  "end_time": "2125-11-22T00:00:00.000Z"
}
```

**Note:** The API key is ONLY returned on creation. Store it securely!

---

### Update User
```
PATCH /api/v1/users/:id
PUT /api/v1/users/:id
```

**Available On:**
- ✅ Production: `https://betstack-45ae7ff725cd.herokuapp.com/api/v1/users/:id`
- ❌ Edge: Not available (proxied to production for security)

**Request Body:**
```json
{
  "email": "updated@example.com",
  "active": false
}
```

---

## 🔄 Edge Cache Sync Schedule

The Cloudflare Edge cache is automatically synced from production on the following schedule:

### Critical Endpoints (Synced Every 2 Minutes)
These endpoints change frequently and are synced often:
- `/api/v1/events`
- `/api/v1/lines`
- `/api/v1/lines/incomplete`
- `/api/v1/results`
- All North American variants and league-specific endpoints

### Static Endpoints (Synced Every 30 Minutes)
These endpoints rarely change:
- `/api/v1/sports`
- `/api/v1/leagues`
- `/api/v1/teams`
- `/api/v1/bookmakers`

---

## 📝 Major North American Leagues

The following leagues are considered "major North American leagues" and have special cached endpoints:

| League Key | Name |
|-----------|------|
| `basketball_nba` | NBA |
| `americanfootball_nfl` | NFL |
| `icehockey_nhl` | NHL |
| `baseball_mlb` | MLB |
| `americanfootball_ncaaf` | NCAAF |
| `basketball_ncaab` | NCAAB |

---

## ⚡ Rate Limiting

- **Limit:** 1,000 requests per day per API key
- **Reset:** Daily at midnight UTC
- **Headers:** All responses include rate limit information:
  - `X-RateLimit-Limit`: Maximum requests per day
  - `X-RateLimit-Remaining`: Requests remaining
  - `X-RateLimit-Reset`: Unix timestamp when limit resets

**Example Response Headers:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1732320000
```

---

## 🚨 Error Responses

All errors follow this format:

```json
{
  "error": "Error Type",
  "message": "Detailed error message"
}
```

### Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created (for POST requests) |
| 400 | Bad Request |
| 401 | Unauthorized (invalid or missing API key) |
| 404 | Not Found |
| 422 | Unprocessable Entity (validation errors) |
| 429 | Rate Limit Exceeded |
| 500 | Internal Server Error |

---

## 📚 Quick Reference Summary

### Endpoints by Availability

#### Available on BOTH Production AND Edge (Cached)
- ✅ `GET /api/v1/sports`
- ✅ `GET /api/v1/leagues`
- ✅ `GET /api/v1/teams`
- ✅ `GET /api/v1/bookmakers`
- ✅ `GET /api/v1/events`
- ✅ `GET /api/v1/lines`
- ✅ `GET /api/v1/lines/incomplete`
- ✅ `GET /api/v1/results`

#### Production Only (Not Cached)
- ✅ `GET /api/v1/sports/:id`
- ✅ `GET /api/v1/leagues/:id`
- ✅ `GET /api/v1/teams/:id`
- ✅ `GET /api/v1/bookmakers/:id`
- ✅ `GET /api/v1/events/:id`
- ✅ `GET /api/v1/results/:id`
- ✅ `GET /api/v1/users`
- ✅ `GET /api/v1/users/:id`
- ✅ `POST /api/v1/users`
- ✅ `PATCH /api/v1/users/:id`
- ✅ `GET /usage`
- ✅ `GET /usage.json`

---

## 💡 Best Practices

1. **Use the Edge for High-Frequency Requests**
   - The Edge (Cloudflare) endpoints are faster and cached
   - Use for collection endpoints (`/api/v1/lines`, `/api/v1/events`, etc.)

2. **Use Production for Single Resource Lookups**
   - Individual resource endpoints (`:id`) are not cached
   - Use production URL for these

3. **Leverage Pre-Cached Endpoints**
   - `?north_american=true` endpoints are pre-cached for speed
   - League-specific endpoints for major leagues are also pre-cached

4. **Monitor Your Rate Limits**
   - Check response headers for rate limit info
   - Visit `/usage` dashboard to track daily usage

5. **Cache Responses Client-Side**
   - Events and lines change every 2 minutes on edge
   - Sports, leagues, teams change every 30 minutes
   - Cache responses appropriately in your application

---

**End of API Reference**

