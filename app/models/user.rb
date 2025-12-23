class User < ApplicationRecord
  # Password handling with bcrypt
  has_secure_password
  
  # Store the plain password temporarily for emails (not persisted)
  attr_accessor :plain_password
  
  # Validations
  validates :api_key, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :phone_number, presence: true, uniqueness: true
  validates :start_time, :end_time, presence: true
  validates :end_time, comparison: { greater_than: :start_time }, if: -> { start_time.present? && end_time.present? }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # Callbacks
  before_validation :normalize_phone_number, on: :create
  before_validation :normalize_email, on: :create
  before_validation :generate_api_key, on: :create
  before_validation :generate_password, on: :create
  before_validation :set_default_times, on: :create

  # Scopes
  scope :active, -> { where(active: true).where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :valid, -> { where(active: true).where(deleted_at: nil).where('start_time <= ? AND end_time >= ?', Time.current, Time.current) }
  
  # Check if a deleted user exists with this email (for reactivation)
  def self.find_deleted_by_email(email)
    normalized = normalize_email_static(email)
    where.not(deleted_at: nil).find_by('LOWER(email) = ?', normalized&.downcase)
  end
  
  # Normalize email for lookup (class method)
  def self.normalize_email_static(email)
    return nil unless email.present?
    
    normalized = email.downcase.strip
    local_part, domain = normalized.split('@', 2)
    return normalized unless domain
    
    # Remove plus addressing
    local_part = local_part.split('+').first
    
    # Remove periods for Gmail
    if domain =~ /^(gmail\.com|googlemail\.com)$/
      local_part = local_part.gsub('.', '')
    end
    
    "#{local_part}@#{domain}"
  end
  
  # Reactivate a deleted user with a new API key and password
  def reactivate!(new_phone: nil)
    self.deleted_at = nil
    self.active = true
    self.phone_number = new_phone if new_phone.present?
    self.start_time = Time.current
    self.end_time = 100.years.from_now
    
    # Generate new API key
    loop do
      self.api_key = SecureRandom.hex(32)
      break unless User.where.not(id: id).exists?(api_key: api_key)
    end
    
    # Generate new password
    self.plain_password = generate_random_password
    self.password = plain_password
    
    save!
  end
  
  # Generate password reset token
  # Note: Column is named reset_token to avoid conflict with Rails 7.1+ has_secure_password
  # which automatically adds a password_reset_token method
  def generate_reset_token!
    self.reset_token = SecureRandom.urlsafe_base64(32)
    self.reset_token_sent_at = Time.current
    save!
  end
  
  # Check if password reset token is valid (expires after 2 hours)
  def reset_token_valid?
    reset_token_sent_at.present? && reset_token_sent_at > 2.hours.ago
  end
  
  # Clear password reset token
  def clear_reset_token!
    self.reset_token = nil
    self.reset_token_sent_at = nil
    save!
  end

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
  
  # Generate random 8-character alphanumeric password
  def generate_password
    return if password_digest.present?
    
    self.plain_password = generate_random_password
    self.password = plain_password
  end
  
  # Generate a random 8-character alphanumeric password
  def generate_random_password
    chars = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
    8.times.map { chars.sample }.join
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

  # Normalize email to prevent duplicate accounts
  # - Converts to lowercase
  # - Removes periods from Gmail/Google Workspace addresses (shawn.lindsey@gmail.com → shawnlindsey@gmail.com)
  # - Removes plus addressing for all providers (shawn+test@gmail.com → shawn@gmail.com)
  def normalize_email
    return unless email.present?

    # Downcase and strip whitespace
    normalized = email.downcase.strip
    
    # Split into local and domain parts
    local_part, domain = normalized.split('@', 2)
    return unless domain # Invalid email format
    
    # Remove plus addressing (everything after +)
    # e.g., shawn+test@gmail.com → shawn@gmail.com
    local_part = local_part.split('+').first
    
    # Remove periods for Gmail and Google Workspace domains
    # Gmail ignores periods in usernames
    if domain =~ /^(gmail\.com|googlemail\.com)$/
      local_part = local_part.gsub('.', '')
    end
    
    self.email = "#{local_part}@#{domain}"
  end
end
