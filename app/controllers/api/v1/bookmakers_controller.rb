# API controller for Bookmakers
# Provides endpoints to browse bookmakers (sportsbooks)

class Api::V1::BookmakersController < Api::V1::BaseController
  # GET /api/v1/bookmakers
  # Returns all bookmakers
  # Params: active=true
  def index
    bookmakers = Bookmaker.all
    bookmakers = bookmakers.active if params[:active] == 'true'
    bookmakers = bookmakers.order(:name)

    render_collection(bookmakers, :api_json)
  end

  # GET /api/v1/bookmakers/:id
  # Returns a single bookmaker
  def show
    bookmaker = Bookmaker.find_by(id: params[:id])
    
    if bookmaker
      render_resource(bookmaker, :api_json_detailed)
    else
      render_not_found("Bookmaker")
    end
  end
end

