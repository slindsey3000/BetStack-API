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
end
