# 🎉 BetStack API - Complete Endpoint Documentation

**Status:** ✅ **LIVE ON HEROKU**  
**Base URL:** `https://betstack-45ae7ff725cd.herokuapp.com`  
**Version:** v1  
**Release:** v14

---

## 📊 Quick Examples

### Get NFL Upcoming Events
```bash
curl "https://betstack-45ae7ff725cd.herokuapp.com/api/v1/events?league_key=americanfootball_nfl&per_page=10"
```

### Get DraftKings NFL Lines
```bash
curl "https://betstack-45ae7ff725cd.herokuapp.com/api/v1/lines?league_key=americanfootball_nfl&bookmaker_key=draftkings"
```

### Get All Major Leagues
```bash
curl "https://betstack-45ae7ff725cd.herokuapp.com/api/v1/leagues?per_page=20"
```

---

## 🔗 Complete API Endpoints (14 total)

### 📊 Sports & Leagues

#### Get All Sports
```
GET /api/v1/sports
```
**Query Params:**
- `active=true` - Only active sports
- `page=1` - Page number
- `per_page=50` - Items per page (max 200)

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "American Football",
      "description": "American Football sports",
      "active": true,
      "leagues_count": 6
    }
  ],
  "meta": { "total": 12, "page": 1, "per_page": 50, "total_pages": 1 }
}
```

#### Get Single Sport
```
GET /api/v1/sports/:id
```
**Response:** Includes list of leagues

---

#### Get All Leagues
```
GET /api/v1/leagues
```
**Query Params:**
- `active=true` - Only active leagues
- `sport_id=1` - Filter by sport

**Response:**
```json
{
  "data": [
    {
      "id": 4,
      "key": "americanfootball_nfl",
      "name": "NFL",
      "region": "us",
      "active": true,
      "has_outrights": false,
      "sport": { "id": 1, "name": "American Football" }
    }
  ],
  "meta": { ... }
}
```

#### Get Single League
```
GET /api/v1/leagues/:id
```

---

### 🏈 Events (Games/Matches)

#### Get All Events
```
GET /api/v1/events
```
**Query Params:**
- `status=upcoming` - Filter by status (upcoming|live|completed)
- `league_key=americanfootball_nfl` - Filter by league
- `date=2025-11-01` - Filter by specific date
- `page=1`, `per_page=50`

**Default Behavior:** Returns upcoming and live events only

**Response:**
```json
{
  "data": [
    {
      "id": 68,
      "odds_api_id": "6031b513e188fc19a2311499566c9258",
      "commence_time": "2025-11-02T18:00:00.000Z",
      "status": "scheduled",
      "completed": false,
      "league": {
        "id": 4,
        "key": "americanfootball_nfl",
        "name": "NFL"
      },
      "home_team": { "id": 120, "name": "Green Bay Packers" },
      "away_team": { "id": 121, "name": "Carolina Panthers" }
    }
  ],
  "meta": { "total": 27, "page": 1, "per_page": 50, "total_pages": 1 }
}
```

#### Get Single Event
```
GET /api/v1/events/:id
```
**Response:** Includes lines from all bookmakers and result (if completed)

---

### 💰 Lines (Betting Odds)

#### Get All Lines
```
GET /api/v1/lines
```
**Query Params:**
- `event_id=123` - Lines for specific event
- `league_key=americanfootball_nfl` - Lines for specific league
- `bookmaker_key=draftkings` - Lines from specific bookmaker
- `date=2025-11-01` - Lines for specific date
- `page=1`, `per_page=50`

**Default Behavior:** Returns lines for upcoming/live events only

**Response:**
```json
{
  "data": [
    {
      "id": 457,
      "event_id": 67,
      "event": {
        "id": 67,
        "commence_time": "2025-11-02T18:00:00.000Z",
        "home_team": "New England Patriots",
        "away_team": "Atlanta Falcons",
        "league": { "key": "americanfootball_nfl", "name": "NFL" }
      },
      "bookmaker": {
        "id": 8,
        "key": "draftkings",
        "name": "DraftKings"
      },
      "moneyline": {
        "home": "-250.0",
        "away": "205.0",
        "draw": null
      },
      "spread": {
        "home": { "point": "-5.5", "price": "-110.0" },
        "away": { "point": "5.5", "price": "-110.0" }
      },
      "total": {
        "number": "45.5",
        "over": "-108.0",
        "under": "-112.0"
      },
      "last_updated": "2025-10-31T22:10:41.000Z",
      "source": "the-odds-api"
    }
  ],
  "meta": { ... }
}
```

---

### 🏆 Results (Scores)

#### Get All Results
```
GET /api/v1/results
```
**Query Params:**
- `league_key=americanfootball_nfl` - Results for specific league
- `date=2025-11-01` - Results for specific date
- `event_id=123` - Result for specific event
- `page=1`, `per_page=50`

**Default Behavior:** Returns results from last 7 days only

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "event_id": 45,
      "home_score": 24,
      "away_score": 17,
      "total_score": 41,
      "final": true,
      "event": {
        "id": 45,
        "commence_time": "2025-10-28T18:00:00.000Z",
        "home_team": "Dallas Cowboys",
        "away_team": "Philadelphia Eagles",
        "league": { "key": "americanfootball_nfl", "name": "NFL" }
      }
    }
  ],
  "meta": { ... }
}
```

#### Get Single Result
```
GET /api/v1/results/:id
```
**Response:** Includes winner information

---

### 👥 Teams

#### Get All Teams
```
GET /api/v1/teams
```
**Query Params:**
- `league_key=americanfootball_nfl` - Teams in specific league
- `active=true` - Only active teams
- `page=1`, `per_page=50`

**Response:**
```json
{
  "data": [
    {
      "id": 120,
      "name": "Green Bay Packers",
      "normalized_name": "green_bay_packers",
      "abbreviation": null,
      "city": null,
      "active": true,
      "league": {
        "id": 4,
        "key": "americanfootball_nfl",
        "name": "NFL"
      }
    }
  ],
  "meta": { ... }
}
```

#### Get Single Team
```
GET /api/v1/teams/:id
```
**Response:** Includes conference and division info

---

### 🎰 Bookmakers

#### Get All Bookmakers
```
GET /api/v1/bookmakers
```
**Query Params:**
- `active=true` - Only active bookmakers
- `page=1`, `per_page=50`

**Response:**
```json
{
  "data": [
    {
      "id": 8,
      "key": "draftkings",
      "name": "DraftKings",
      "description": null,
      "region": "us",
      "active": true
    }
  ],
  "meta": { ... }
}
```

#### Get Single Bookmaker
```
GET /api/v1/bookmakers/:id
```
**Response:** Includes line count

---

## 🔑 League Keys

Use these keys for filtering:

### Major North American Leagues (actively synced)
- `americanfootball_nfl` - NFL
- `basketball_nba` - NBA
- `icehockey_nhl` - NHL
- `baseball_mlb` - MLB
- `americanfootball_ncaaf` - College Football
- `basketball_ncaab` - College Basketball

---

## 🎲 Bookmaker Keys

- `draftkings` - DraftKings
- `fanduel` - FanDuel
- `betmgm` - BetMGM
- `bovada` - Bovada
- `betus` - BetUS
- And 4 more...

---

## 📋 Response Format

All endpoints return JSON with this structure:

```json
{
  "data": [ ... ],      // Array of resources (or single object for show endpoints)
  "meta": {             // Pagination metadata (collection endpoints only)
    "total": 100,
    "page": 1,
    "per_page": 50,
    "total_pages": 2
  }
}
```

---

## 🚀 Pagination

- **Default:** 50 items per page
- **Maximum:** 200 items per page
- **Query Params:**
  - `page=1` - Page number (starts at 1)
  - `per_page=50` - Items per page

---

## 🔄 Data Sync Schedule

Data is automatically synced from The Odds API:

- **Sports/Leagues:** Once daily (6am)
- **Odds/Lines:** 3x daily (8am, 2pm, 8pm)
- **Scores:** Every hour

---

## 💡 Usage Tips

1. **Combine Filters:** `?league_key=americanfootball_nfl&status=upcoming&per_page=20`
2. **Bookmaker Comparison:** Get lines for same event from multiple bookmakers
3. **Date Ranges:** Use date filter for historical or future events
4. **Smart Defaults:** API automatically filters out old data

---

## 🛠️ Implementation

- **Framework:** Ruby on Rails 8 API
- **Database:** PostgreSQL (Heroku)
- **Data Source:** The Odds API
- **Background Jobs:** Solid Queue
- **Deployment:** Heroku

---

## 📚 Related Documentation

- **Data Ingestion:** `DATA_INGESTION_COMPLETE.md`
- **League Optimization:** `LEAGUE_OPTIMIZATION.md`
- **Setup Guide:** `SETUP_COMPLETE.md`

---

**Built:** October 31, 2025  
**Last Updated:** November 1, 2025  
**Status:** ✅ Production Ready
