# The Odds API Configuration
#
# Configuration for The Odds API integration
# https://the-odds-api.com/liveapi/guides/v4/

module OddsApi
  class Configuration
    attr_accessor :api_key, :base_url, :default_region, :default_odds_format, :default_markets

    def initialize
      @api_key = ENV.fetch('ODDS_API_KEY', nil)
      @base_url = ENV.fetch('ODDS_API_BASE_URL', 'https://api.the-odds-api.com/v4')
      @default_region = 'us'
      @default_odds_format = 'american'
      @default_markets = ['h2h', 'spreads', 'totals']
    end

    def configured?
      api_key.present? && base_url.present?
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

# Validate configuration on initialization
if Rails.env.development? || Rails.env.production?
  unless OddsApi.configuration.configured?
    Rails.logger.warn "⚠️  The Odds API is not fully configured. Please set ODDS_API_KEY in your environment."
  else
    Rails.logger.info "✅ The Odds API configured: #{OddsApi.configuration.base_url}"
  end
end

