class Team < ApplicationRecord
  # Associations
  belongs_to :league
  has_many :home_events, class_name: "Event", foreign_key: "home_team_id", dependent: :restrict_with_error
  has_many :away_events, class_name: "Event", foreign_key: "away_team_id", dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :normalized_name, uniqueness: { scope: :league_id }, allow_nil: true

  # Callbacks
  before_validation :set_normalized_name, if: -> { name.present? && normalized_name.blank? }

  # Scopes
  scope :active, -> { where(active: true) }

  private

  def set_normalized_name
    self.normalized_name = name.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
  end
end
