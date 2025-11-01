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
    'basketball_nba',       # NBA
    'americanfootball_nfl', # NFL
    'icehockey_nhl',        # NHL
    'baseball_mlb',         # MLB
    'americanfootball_ncaaf', # NCAAF
    'basketball_ncaab'      # NCAAB
  ].freeze
  
  scope :major_north_american, -> { where(key: MAJOR_NORTH_AMERICAN_LEAGUES) }

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
