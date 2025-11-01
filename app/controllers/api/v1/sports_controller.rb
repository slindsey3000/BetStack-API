# API controller for Sports
# Provides endpoints to browse all sports and their leagues

class Api::V1::SportsController < Api::V1::BaseController
  # GET /api/v1/sports
  # Returns all sports, optionally filtered by active status
  def index
    sports = Sport.all
    sports = sports.active if params[:active] == 'true'
    sports = sports.includes(:leagues).order(:name)

    render_collection(sports, :api_json)
  end

  # GET /api/v1/sports/:id
  # Returns a single sport with its leagues
  def show
    sport = Sport.includes(:leagues).find_by(id: params[:id])
    
    if sport
      render_resource(sport, :api_json_detailed)
    else
      render_not_found("Sport")
    end
  end
end

