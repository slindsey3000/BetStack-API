class League < ApplicationRecord
  # Associations
  belongs_to :sport
  has_many :teams, dependent: :destroy
  has_many :events, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :key, presence: true, uniqueness: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :with_outrights, -> { where(has_outrights: true) }

  # Major North American leagues for focused syncing
  MAJOR_NORTH_AMERICAN_LEAGUES = [
    "basketball_nba",       # NBA
    "americanfootball_nfl", # NFL
    "icehockey_nhl",        # NHL
    "baseball_mlb",         # MLB
    "americanfootball_ncaaf", # NCAAF
    "basketball_ncaab"      # NCAAB
  ].freeze

  scope :major_north_american, -> { where(key: MAJOR_NORTH_AMERICAN_LEAGUES) }

  # Season definitions - calendar month ranges for each league
  # Used for smart scheduling to determine when to sync odds/results
  LEAGUE_SEASONS = {
    'basketball_nba' => { start_month: 10, end_month: 4 },      # October - April
    'americanfootball_nfl' => { start_month: 9, end_month: 2 }, # September - February
    'baseball_mlb' => { start_month: 4, end_month: 10 },        # April - October
    'icehockey_nhl' => { start_month: 10, end_month: 4 },       # October - April
    'americanfootball_ncaaf' => { start_month: 8, end_month: 1 }, # August - January
    'basketball_ncaab' => { start_month: 11, end_month: 4 }     # November - April
  }.freeze

  # Check if league is currently in season based on calendar month
  def in_season?
    season = LEAGUE_SEASONS[key]
    return false unless season
    
    current_month = Time.current.month
    start_month = season[:start_month]
    end_month = season[:end_month]
    
    if start_month <= end_month
      # Season within same calendar year (e.g., MLB: April-October)
      current_month >= start_month && current_month <= end_month
    else
      # Season spans calendar year (e.g., NBA: October-April)
      current_month >= start_month || current_month <= end_month
    end
  end

  # Smart scheduling sync tracking
  # Check if league needs odds sync based on frequency
  def needs_odds_sync?(frequency_seconds)
    last_odds_sync_at.nil? || 
    last_odds_sync_at < frequency_seconds.seconds.ago
  end

  # Check if league needs results sync based on frequency
  def needs_results_sync?(frequency_seconds)
    last_results_sync_at.nil? || 
    last_results_sync_at < frequency_seconds.seconds.ago
  end

  # Update last odds sync timestamp
  def update_odds_sync_time!
    update_column(:last_odds_sync_at, Time.current)
  end

  # Update last results sync timestamp
  def update_results_sync_time!
    update_column(:last_results_sync_at, Time.current)
  end

  # API Serialization
  def api_json
    {
      id: id,
      key: key,
      name: name,
      region: region,
      active: active,
      has_outrights: has_outrights,
      sport: {
        id: sport.id,
        name: sport.name
      }
    }
  end

  def api_json_detailed
    api_json.merge(
      teams_count: teams.count,
      upcoming_events_count: events.upcoming.count
    )
  end
end
