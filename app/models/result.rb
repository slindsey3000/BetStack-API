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
end
