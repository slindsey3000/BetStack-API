# 📮 BetStack API - Postman Collection Guide

## 🚀 Quick Start

### Import the Collection

1. Open Postman
2. Click "Import" in the top left
3. Select `BetStack_API.postman_collection.json` from this directory
4. The collection will appear in your sidebar

---

## 🔧 Environment Setup

The collection includes two URL variables:

### Local Development
```
base_url = http://localhost:3000
```

### Production (Heroku)
```
production_url = https://betstack-45ae7ff725cd.herokuapp.com
```

### Switching Between Environments

**Option 1: Edit Collection Variable**
1. Right-click the collection → Edit
2. Go to Variables tab
3. Change `base_url` current value from `http://localhost:3000` to `{{production_url}}`

**Option 2: Create Postman Environments**
1. Create "Local" environment with `base_url = http://localhost:3000`
2. Create "Production" environment with `base_url = https://betstack-45ae7ff725cd.herokuapp.com`
3. Select environment from dropdown in top-right

---

## 📁 Collection Structure (47 Requests)

### 1️⃣ Sports (3 requests)
- Get All Sports
- Get All Sports (Active Only)
- Get Single Sport

### 2️⃣ Leagues (4 requests)
- Get All Leagues
- Get All Leagues (Active Only)
- Get Leagues by Sport
- Get Single League

### 3️⃣ Events (10 requests)
- Get All Events
- Get NFL Events
- Get NBA Events
- Get NHL Events
- Get MLB Events
- Get Upcoming Events
- Get Live Events
- Get Completed Events
- Get Events by Date
- Get Single Event

### 4️⃣ Lines/Odds (7 requests)
- Get All Lines
- Get NFL Lines
- Get DraftKings Lines
- Get FanDuel Lines
- Get NFL DraftKings Lines
- Get Lines for Event
- Get Lines by Date

### 5️⃣ Results (5 requests)
- Get All Results
- Get NFL Results
- Get Results by Date
- Get Result for Event
- Get Single Result

### 6️⃣ Teams (5 requests)
- Get All Teams
- Get All Teams (Active Only)
- Get NFL Teams
- Get NBA Teams
- Get Single Team

### 7️⃣ Bookmakers (3 requests)
- Get All Bookmakers
- Get All Bookmakers (Active Only)
- Get Single Bookmaker

---

## 💡 Usage Tips

### Testing Workflow

1. **Start with Sports & Leagues**
   - Get all leagues to see available league_keys
   - Common keys: `americanfootball_nfl`, `basketball_nba`, `icehockey_nhl`, `baseball_mlb`

2. **Browse Events**
   - Use league_key filter to see games for specific league
   - Use date filter for specific days
   - Use status filter for upcoming/live/completed

3. **Get Betting Lines**
   - Filter by league_key and bookmaker_key for specific odds
   - Get all lines for an event_id to compare bookmakers
   - Common bookmaker keys: `draftkings`, `fanduel`, `betmgm`

4. **Check Results**
   - View completed game scores
   - Filter by league or date

### Common Query Patterns

**Get all NFL games with DraftKings odds:**
```
1. Events → Get NFL Events
2. Copy an event ID from response
3. Lines → Get Lines for Event (change event_id parameter)
```

**Compare odds across bookmakers:**
```
1. Lines → Get NFL Lines (shows all bookmakers)
2. Filter response by event ID to see all bookmaker lines
```

**Check today's games:**
```
1. Events → Get Events by Date (set date=2025-11-02)
```

---

## 🔑 Important Keys

### League Keys (Major North American)
- `americanfootball_nfl` - NFL
- `basketball_nba` - NBA
- `icehockey_nhl` - NHL
- `baseball_mlb` - MLB
- `americanfootball_ncaaf` - College Football
- `basketball_ncaab` - College Basketball

### Bookmaker Keys
- `draftkings` - DraftKings
- `fanduel` - FanDuel
- `betmgm` - BetMGM
- `bovada` - Bovada
- `betus` - BetUS
- `lowvig` - LowVig.ag
- `mybookieag` - MyBookie.ag
- `betonlineag` - BetOnline.ag
- `betrivers` - BetRivers

### Event Status
- `upcoming` - Events that haven't started
- `live` - Events currently in progress
- `completed` - Events that have finished (last 3 days)

---

## 📊 Response Examples

### Events Response (Clean Array)
```json
[
  {
    "id": 68,
    "commence_time": "2025-11-02T18:00:00.000Z",
    "status": "scheduled",
    "completed": false,
    "league": { "key": "americanfootball_nfl", "name": "NFL" },
    "home_team": { "id": 120, "name": "Green Bay Packers" },
    "away_team": { "id": 121, "name": "Carolina Panthers" }
  }
]
```

### Lines Response (with Odds)
```json
[
  {
    "event": { "home_team": "Patriots", "away_team": "Falcons" },
    "bookmaker": { "key": "draftkings", "name": "DraftKings" },
    "moneyline": { "home": "-250.0", "away": "205.0" },
    "spread": {
      "home": { "point": "-5.5", "price": "-110.0" },
      "away": { "point": "5.5", "price": "-110.0" }
    },
    "total": { "number": "45.5", "over": "-108.0", "under": "-112.0" }
  }
]
```

---

## 🧪 Testing Local vs Production

### Before Testing Locally
1. Start Rails server: `rails s`
2. Make sure data is seeded: `rails odds:sync`
3. Use `base_url` in collection

### Testing Production
1. Change `base_url` to `{{production_url}}`
2. Or create Production environment
3. Data syncs automatically 3x daily

---

## 🔄 Keeping Collection Updated

When new endpoints are added:
1. Add new request to appropriate folder
2. Use existing requests as templates
3. Include description of what the endpoint does
4. Test with both local and production URLs
5. Commit updated `BetStack_API.postman_collection.json`

---

## 📚 Additional Resources

- **API Documentation:** `API_ENDPOINTS.md`
- **Cursor Rules:** `.cursorrules`
- **Setup Guide:** `SETUP_COMPLETE.md`

---

**Collection Version:** 1.0  
**Last Updated:** November 1, 2025  
**Total Requests:** 47
