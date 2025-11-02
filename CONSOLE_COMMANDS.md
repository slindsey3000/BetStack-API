# 🖥️ BetStack API - Console Commands Reference

## Quick Start

Open Rails console:
```bash
rails c
```

All these methods are available directly in the console!

---

## 📊 Getting Lines (Odds)

### Quick Shortcuts

```ruby
# Get NFL lines
nfl_lines

# Get NBA lines
nba_lines

# Get NHL lines
nhl_lines

# Get MLB lines
mlb_lines
```

### With Bookmaker Filter

```ruby
# NFL lines from DraftKings only
nfl_lines(bookmaker_key: "draftkings")

# NBA lines from FanDuel only
nba_lines(bookmaker_key: "fanduel")
```

### Generic Method

```ruby
# Get lines for any league
lines_for("americanfootball_nfl")
lines_for("basketball_nba", bookmaker_key: "draftkings")
```

---

## 🔄 Refreshing Odds

### Quick Shortcuts

```ruby
# Refresh NFL odds
refresh_nfl

# Refresh NBA odds
refresh_nba

# Refresh NHL odds
refresh_nhl

# Refresh MLB odds
refresh_mlb
```

### Generic Method

```ruby
# Refresh odds for any league
refresh_odds("americanfootball_nfl")
refresh_odds("basketball_nba")
```

### Refresh All Major Leagues

```ruby
# Refresh odds for all 6 major North American leagues
refresh_all_odds
```

---

## 🏆 Refreshing Results (Scores)

### Quick Shortcuts

```ruby
# Refresh NFL results
refresh_nfl_results

# Refresh NBA results
refresh_nba_results
```

### Generic Method

```ruby
# Refresh results for any league
refresh_results("americanfootball_nfl")
refresh_results("basketball_nba")
```

### Refresh All Results

```ruby
# Refresh results for all major leagues
refresh_all_results
```

---

## 📈 Viewing Statistics

```ruby
# Get stats for a league
league_stats("americanfootball_nfl")
league_stats("basketball_nba")
```

---

## 📝 Examples

### Common Workflow

```ruby
# 1. Check current NFL lines
nfl_lines

# 2. Refresh to get latest odds
refresh_nfl

# 3. Check updated lines
nfl_lines

# 4. Check stats
league_stats("americanfootball_nfl")
```

### Filter by Bookmaker

```ruby
# See only DraftKings NFL lines
nfl_lines(bookmaker_key: "draftkings")

# Refresh and check again
refresh_nfl
nfl_lines(bookmaker_key: "draftkings")
```

### Get Results After Games Finish

```ruby
# Refresh NFL scores
refresh_nfl_results

# View results via API or console
Result.joins(event: :league).where(leagues: { key: "americanfootball_nfl" }).last(5)
```

---

## 🔑 Available League Keys

- `americanfootball_nfl` - NFL
- `basketball_nba` - NBA
- `icehockey_nhl` - NHL
- `baseball_mlb` - MLB
- `americanfootball_ncaaf` - College Football
- `basketball_ncaab` - College Basketball

---

## 📚 Related Rake Tasks

These console helpers are wrappers around rake tasks. You can also use:

```bash
# Refresh odds via rake
rails odds:sync_league[americanfootball_nfl]

# Refresh all odds
rails odds:sync

# Refresh scores
rails odds:sync_scores[americanfootball_nfl]

# View stats
rails odds:stats
```

---

## 💡 Tips

1. **Console helpers return data** - You can assign results to variables:
   ```ruby
   lines = nfl_lines
   lines.count
   ```

2. **Chain with ActiveRecord** - Helpers return ActiveRecord relations, so you can chain:
   ```ruby
   nfl_lines.where("events.commence_time > ?", 1.day.from_now)
   ```

3. **Pretty printing** - Use `pp` for better output:
   ```ruby
   pp nfl_lines.first
   ```

---

**Last Updated:** November 1, 2025  
**Available in:** Rails console (`rails c`)

