# API controller for Events
# Provides endpoints to browse events (games/matches)

class Api::V1::EventsController < Api::V1::BaseController
  # GET /api/v1/events
  # Returns events with smart filtering
  # Params: status=(upcoming|live|completed), league_key=nfl, date=2025-11-01
  def index
    events = Event.includes(:league, :home_team, :away_team)

    # Filter by status (default: upcoming and live)
    case params[:status]
    when 'upcoming'
      events = events.upcoming
    when 'live'
      events = events.live
    when 'completed'
      # Only recent completed events (last 3 days)
      events = events.completed.where('commence_time > ?', 3.days.ago)
    else
      # Default: upcoming and live only
      events = events.where('commence_time > ? OR (commence_time <= ? AND completed = ?)', 
                           Time.current, Time.current, false)
    end

    # Filter by league
    if params[:league_key].present?
      events = events.joins(:league).where(leagues: { key: params[:league_key] })
    end

    # Filter by date
    if params[:date].present?
      begin
        date = Date.parse(params[:date])
        events = events.where(commence_time: date.all_day)
      rescue ArgumentError
        # Invalid date, ignore filter
      end
    end

    events = events.order(commence_time: :asc)

    render_collection(events, :api_json)
  end

  # GET /api/v1/events/:id
  # Returns a single event with lines and result
  def show
    event = Event.includes(:league, :home_team, :away_team, :lines, :result)
                 .find_by(id: params[:id])
    
    if event
      render_resource(event, :api_json_detailed)
    else
      render_not_found("Event")
    end
  end
end

