# API controller for Teams
# Provides endpoints to browse teams

class Api::V1::TeamsController < Api::V1::BaseController
  # GET /api/v1/teams
  # Returns all teams
  # Params: league_key=nfl, active=true
  def index
    teams = Team.includes(:league).all
    teams = teams.active if params[:active] == 'true'
    
    # Filter by league
    if params[:league_key].present?
      teams = teams.joins(:league).where(leagues: { key: params[:league_key] })
    end

    teams = teams.order(:name)

    render_collection(teams, :api_json)
  end

  # GET /api/v1/teams/:id
  # Returns a single team
  def show
    team = Team.includes(:league).find_by(id: params[:id])
    
    if team
      render_resource(team, :api_json_detailed)
    else
      render_not_found("Team")
    end
  end
end

