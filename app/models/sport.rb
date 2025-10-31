class Sport < ApplicationRecord
  # Associations
  has_many :leagues, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
end
