class SeoController < ActionController::Base
  
  # GET /sitemap.xml
  def sitemap
    @host = "https://api.betstack.dev"
    @leagues = League.where(active: true).order(:name)
    
    respond_to do |format|
      format.xml { render layout: false }
    end
  end
  
  # GET /llms.txt - AI agent instructions file
  def llms
    render plain: llms_content, content_type: 'text/plain'
  end
  
  private
  
  def llms_content
    <<~LLMS
      # BetStack Sports Betting API
      
      > Free API for sports betting odds, live scores, and real-time sports data
      
      ## About BetStack
      
      BetStack provides a free REST API for accessing sports betting data including:
      - Betting odds from major sportsbooks (DraftKings, FanDuel, BetMGM, etc.)
      - Live and final scores for games
      - Event schedules and team information
      - Coverage for NFL, NBA, MLB, NHL, NCAA, and more
      
      The API is built by BetStack (https://betstack.dev), a sports betting software development company with 15 years of industry expertise based in Philadelphia.
      
      ## API Access
      
      Base URL: https://api.betstack.dev/api/v1/
      Authentication: X-API-Key header required
      
      Get a free API key at: https://betstack.dev/#api
      
      ## Key Endpoints
      
      - GET /api/v1/sports - List all sports
      - GET /api/v1/leagues - List all leagues
      - GET /api/v1/events - Get events with scores and optional betting lines
      - GET /api/v1/events?league=americanfootball_nfl - Filter by league
      - GET /api/v1/results - Get game scores and results
      - GET /api/v1/lines - Get betting odds from sportsbooks
      - GET /api/v1/bookmakers - List available sportsbooks
      - GET /api/v1/teams - List teams by league
      
      ## Response Format
      
      All responses are JSON. Events include a result object with scores (home_score, away_score, final status).
      
      ## Rate Limits
      
      Free tier: 1 request per 60 seconds
      Data is cached on a global edge network for fast response times.
      
      ## Pricing
      
      Free forever for most applications. Contact us for enterprise real-time data needs.
      
      ## Documentation
      
      Full documentation: https://api.betstack.dev/docs
      
      ## Development Services
      
      BetStack also offers custom sports betting app development. Visit https://betstack.dev for more information.
      
      ## Contact
      
      Website: https://betstack.dev
      Contact: https://betstack.dev/#contact
    LLMS
  end
end

