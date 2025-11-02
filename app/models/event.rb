class Event < ApplicationRecord
  # Associations
  belongs_to :league
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  has_many :lines, dependent: :destroy
  has_one :result, dependent: :destroy

  # Validations
  validates :odds_api_id, presence: true, uniqueness: true
  validates :home_team_id, :away_team_id, presence: true
  validate :teams_must_be_different

  # Scopes
  scope :upcoming, -> { where("commence_time > ?", Time.current).where(completed: false) }
  scope :live, -> { where("commence_time <= ?", Time.current).where(completed: false) }
  scope :completed, -> { where(completed: true) }
  scope :for_league, ->(league_id) { where(league_id: league_id) }
  scope :recent, -> { order(commence_time: :desc) }

  # Enums (optional - if you want to use enum for status)
  # enum status: { scheduled: "scheduled", live: "live", completed: "completed", cancelled: "cancelled", postponed: "postponed" }

  # API Serialization
  def api_json
    {
      id: id,
      odds_api_id: odds_api_id,
      commence_time: commence_time,
      status: status,
      completed: completed,
      league: {
        id: league.id,
        key: league.key,
        name: league.name
      },
      home_team: {
        id: home_team.id,
        name: home_team_name
      },
      away_team: {
        id: away_team.id,
        name: away_team_name
      }
    }
  end

  def api_json_detailed
    # Only include BetStack consensus lines by default
    betstack_bookmaker = Bookmaker.find_by(key: 'betstack')
    consensus_lines = if betstack_bookmaker
                        lines.where(bookmaker: betstack_bookmaker).includes(:bookmaker)
                      else
                        lines.none
                      end
    
    data = api_json.merge(
      lines: consensus_lines.map(&:api_json)
    )
    
    # Include result if exists
    data[:result] = result.api_json if result.present?
    
    data
  end

  private

  def teams_must_be_different
    if home_team_id.present? && home_team_id == away_team_id
      errors.add(:away_team_id, "must be different from home team")
    end
  end
end
