class Sport < ApplicationRecord
  # Associations
  has_many :leagues, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(active: true) }

  # API Serialization
  def api_json
    {
      id: id,
      name: name,
      description: description,
      active: active,
      leagues_count: leagues.count
    }
  end

  def api_json_detailed
    api_json.merge(
      leagues: leagues.map(&:api_json)
    )
  end
end
