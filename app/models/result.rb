class Result < ApplicationRecord
  # Associations
  belongs_to :event

  # Validations
  validates :event_id, uniqueness: true

  # Scopes
  scope :final_only, -> { where(final: true) }

  # Instance methods
  def winner
    return nil unless final && home_score.present? && away_score.present?

    if home_score > away_score
      event.home_team
    elsif away_score > home_score
      event.away_team
    else
      nil # tie/draw
    end
  end

  def total_score
    return nil unless home_score.present? && away_score.present?
    home_score + away_score
  end

  # API Serialization
  def api_json
    {
      id: id,
      event_id: event_id,
      home_score: home_score,
      away_score: away_score,
      total_score: total_score,
      final: final,
      event: {
        id: event.id,
        commence_time: event.commence_time,
        home_team: event.home_team_name,
        away_team: event.away_team_name,
        league: {
          key: event.league.key,
          name: event.league.name
        }
      }
    }
  end

  def api_json_detailed
    api_json.merge(
      winner: winner ? { id: winner.id, name: winner.name } : nil
    )
  end
end
