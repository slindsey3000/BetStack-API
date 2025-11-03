# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create GMoneyApp user with a known API key that works everywhere
# This user is used for testing and development across all environments (local, production, Cloudflare)
# API key format: 64-character hex string (SecureRandom.hex(32))
GMONEY_API_KEY = "476d6f6e657961707032303234626574737461636b6170690000000000000000"

# Find or initialize by API key (more reliable than email due to normalization)
user = User.find_or_initialize_by(api_key: GMONEY_API_KEY)

# Set attributes
user.assign_attributes(
  email: "gmoneyapp@betstack.dev",
  phone_number: "15551234567",
  address: "GMoneyApp Development",
  start_time: Time.current,
  end_time: 100.years.from_now,
  active: true
)

# Save without validations to bypass generate_api_key callback
user.save!(validate: false)

puts "✅ GMoneyApp user created/updated"
puts "   Email: #{user.email}"
puts "   API Key: #{user.api_key}"
puts "   Valid until: #{user.end_time}"
