# API controller for Leagues
# Provides endpoints to browse leagues and their details

class Api::V1::LeaguesController < Api::V1::BaseController
  # GET /api/v1/leagues
  # Returns all leagues, optionally filtered
  # Params: 
  #   - active=true
  #   - sport_id=1
  #   - north_american=true (filter to NBA, NFL, NHL, MLB, NCAAF, NCAAB)
  def index
    leagues = League.includes(:sport).all
    leagues = leagues.active if params[:active] == 'true'
    leagues = leagues.where(sport_id: params[:sport_id]) if params[:sport_id].present?
    
    # Filter to North American leagues
    if params[:north_american] == 'true' || params[:north_american] == true
      leagues = leagues.major_north_american
    end
    
    leagues = leagues.order(:name)

    render_collection(leagues, :api_json)
  end

  # GET /api/v1/leagues/:id
  # Returns a single league with details
  def show
    league = League.includes(:sport).find_by(id: params[:id])
    
    if league
      render_resource(league, :api_json_detailed)
    else
      render_not_found("League")
    end
  end
end

