class User < ApplicationRecord
  # Validations
  validates :api_key, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :phone_number, presence: true, uniqueness: true
  validates :start_time, :end_time, presence: true
  validates :end_time, comparison: { greater_than: :start_time }, if: -> { start_time.present? && end_time.present? }

  # Callbacks
  before_validation :normalize_phone_number, on: :create
  before_validation :normalize_email, on: :create
  before_validation :generate_api_key, on: :create
  before_validation :set_default_times, on: :create

  # Scopes
  scope :active, -> { where(active: true) }
  scope :valid, -> { where(active: true).where('start_time <= ? AND end_time >= ?', Time.current, Time.current) }

  # Instance methods
  def valid_key?
    active? && Time.current >= start_time && Time.current <= end_time
  end

  def expired?
    Time.current > end_time
  end

  def not_yet_valid?
    Time.current < start_time
  end

  # API Serialization
  def api_json
    {
      id: id,
      email: email,
      phone_number: phone_number,
      address: address,
      start_time: start_time,
      end_time: end_time,
      active: active,
      valid_key: valid_key?,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def api_json_with_key
    api_json.merge(api_key: api_key)
  end

  private

  # Generate unique API key
  def generate_api_key
    return if api_key.present?

    loop do
      self.api_key = SecureRandom.hex(32)
      break unless User.exists?(api_key: api_key)
    end
  end

  # Set default times (now and 100 years from now)
  def set_default_times
    return if start_time.present? || end_time.present?

    self.start_time ||= Time.current
    self.end_time ||= 100.years.from_now
  end

  # Normalize phone number (strip formatting, keep numbers only for E.164)
  def normalize_phone_number
    return unless phone_number.present?

    # Strip all non-digit characters for normalization
    self.phone_number = phone_number.gsub(/\D/, '')
  end

  # Normalize email (downcase, remove dots from local part)
  def normalize_email
    return unless email.present?

    email_parts = email.downcase.split('@')
    if email_parts.length == 2
      local_part = email_parts[0].gsub('.', '')
      self.email = "#{local_part}@#{email_parts[1]}"
    end
  end
end
