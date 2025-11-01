# API controller for Results (Scores)
# Provides endpoints to browse game results

class Api::V1::ResultsController < Api::V1::BaseController
  # GET /api/v1/results
  # Returns results for completed events (last 7 days by default)
  # Params: league_key=nfl, date=2025-11-01, event_id=123
  def index
    results = Result.includes(event: [:league, :home_team, :away_team])
                    .joins(:event)

    # Only recent results (last 7 days by default)
    results = results.where('events.commence_time > ?', 7.days.ago)

    # Filter by league
    if params[:league_key].present?
      results = results.joins(event: :league).where(leagues: { key: params[:league_key] })
    end

    # Filter by event
    if params[:event_id].present?
      results = results.where(event_id: params[:event_id])
    end

    # Filter by date
    if params[:date].present?
      begin
        date = Date.parse(params[:date])
        results = results.where(events: { commence_time: date.all_day })
      rescue ArgumentError
        # Invalid date, ignore filter
      end
    end

    results = results.order('events.commence_time DESC')

    render_collection(results, :api_json)
  end

  # GET /api/v1/results/:id
  # Returns a single result
  def show
    result = Result.includes(event: [:league, :home_team, :away_team])
                   .find_by(id: params[:id])
    
    if result
      render_resource(result, :api_json_detailed)
    else
      render_not_found("Result")
    end
  end
end

