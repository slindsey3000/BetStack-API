class Line < ApplicationRecord
  # Associations
  belongs_to :event
  belongs_to :bookmaker

  # Validations
  validates :event_id, uniqueness: { scope: :bookmaker_id, message: "can only have one line per bookmaker" }

  # Scopes
  scope :for_event, ->(event_id) { where(event_id: event_id) }
  scope :for_bookmaker, ->(bookmaker_id) { where(bookmaker_id: bookmaker_id) }
  scope :recent, -> { order(last_updated: :desc) }

  # Instance methods
  def has_moneyline?
    money_line_home.present? || money_line_away.present?
  end

  def has_spread?
    point_spread_home.present? || point_spread_away.present?
  end

  def has_totals?
    total_number.present?
  end

  # API Serialization
  def api_json
    {
      id: id,
      event_id: event_id,
      event: {
        id: event.id,
        commence_time: event.commence_time,
        home_team: event.home_team_name,
        away_team: event.away_team_name,
        league: {
          key: event.league.key,
          name: event.league.name
        }
      },
      bookmaker: {
        id: bookmaker.id,
        key: bookmaker.key,
        name: bookmaker.name
      },
      moneyline: {
        home: money_line_home,
        away: money_line_away,
        draw: draw_line
      },
      spread: {
        home: {
          point: point_spread_home,
          price: point_spread_home_line
        },
        away: {
          point: point_spread_away,
          price: point_spread_away_line
        }
      },
      total: {
        number: total_number,
        over: over_line,
        under: under_line
      },
      last_updated: last_updated,
      source: source
    }
  end
end
