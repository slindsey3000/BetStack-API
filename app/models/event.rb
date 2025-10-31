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

  private

  def teams_must_be_different
    if home_team_id.present? && home_team_id == away_team_id
      errors.add(:away_team_id, "must be different from home team")
    end
  end
end
