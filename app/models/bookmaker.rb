class Bookmaker < ApplicationRecord
  # Associations
  has_many :lines, dependent: :destroy

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_region, ->(region) { where(region: region) }
end
