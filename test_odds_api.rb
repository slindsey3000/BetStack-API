#!/usr/bin/env ruby
# Test script to verify The Odds API connection

require 'faraday'
require 'json'
require 'dotenv/load'

puts "=" * 60
puts "Testing The Odds API Connection"
puts "=" * 60
puts ""

# Check environment variables
api_key = ENV['ODDS_API_KEY']
base_url = ENV['ODDS_API_BASE_URL']

if api_key.nil? || api_key.empty?
  puts "❌ ERROR: ODDS_API_KEY not found in environment"
  exit 1
end

if base_url.nil? || base_url.empty?
  puts "❌ ERROR: ODDS_API_BASE_URL not found in environment"
  exit 1
end

puts "✅ Environment variables loaded:"
puts "   - ODDS_API_KEY: #{api_key[0..10]}... (#{api_key.length} chars)"
puts "   - ODDS_API_BASE_URL: #{base_url}"
puts ""

# Test API connection
puts "Testing API connection..."
puts "Endpoint: GET #{base_url}/sports"
puts ""

begin
  conn = Faraday.new do |f|
    f.response :raise_error  # Raise errors for non-2xx responses
    f.adapter Faraday.default_adapter
  end

  response = conn.get("#{base_url}/sports") do |req|
    req.params['apiKey'] = api_key
  end

  puts "✅ API Connection Successful!"
  puts "   - Status: #{response.status}"
  puts "   - Response Headers:"
  puts "     * x-requests-used: #{response.headers['x-requests-used']}"
  puts "     * x-requests-remaining: #{response.headers['x-requests-remaining']}"
  puts ""

  # Parse and display sports
  sports = JSON.parse(response.body)
  
  puts "📊 Retrieved #{sports.length} sports:"
  puts ""
  
  # Show active sports
  active_sports = sports.select { |s| s['active'] }
  puts "Active Sports (#{active_sports.length}):"
  active_sports.first(10).each do |sport|
    status = sport['has_outrights'] ? "🏆" : "⚽"
    puts "   #{status} #{sport['title']} (#{sport['key']})"
    puts "      Group: #{sport['group']}"
    puts "      Description: #{sport['description']}"
    puts ""
  end

  if active_sports.length > 10
    puts "   ... and #{active_sports.length - 10} more active sports"
    puts ""
  end

  puts "=" * 60
  puts "✅ All tests passed! Ready to integrate with Rails."
  puts "=" * 60

rescue Faraday::Error => e
  puts "❌ ERROR: Failed to connect to The Odds API"
  puts "   Error: #{e.class} - #{e.message}"
  exit 1
rescue JSON::ParserError => e
  puts "❌ ERROR: Failed to parse API response"
  puts "   Error: #{e.message}"
  exit 1
end

