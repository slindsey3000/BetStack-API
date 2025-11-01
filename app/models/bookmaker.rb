class Bookmaker < ApplicationRecord
  # Associations
  has_many :lines, dependent: :destroy

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_region, ->(region) { where(region: region) }

  # API Serialization
  def api_json
    {
      id: id,
      key: key,
      name: name,
      description: description,
      region: region,
      active: active
    }
  end

  def api_json_detailed
    api_json.merge(
      lines_count: lines.count
    )
  end
end
