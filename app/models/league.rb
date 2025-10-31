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
end
