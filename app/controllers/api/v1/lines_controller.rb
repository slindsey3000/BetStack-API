# API controller for Lines (Betting Odds)
# Provides endpoints to browse betting lines

class Api::V1::LinesController < Api::V1::BaseController
  # GET /api/v1/lines
  # Returns betting lines for upcoming events
  # Params: event_id=123, league_key=nfl, bookmaker_key=fanduel, date=2025-11-01
  def index
    lines = Line.includes(:bookmaker, event: [:league, :home_team, :away_team])

    # Only lines for upcoming or live events by default
    lines = lines.joins(:event)
                 .where('events.commence_time > ? OR (events.commence_time <= ? AND events.completed = ?)',
                        Time.current, Time.current, false)

    # Filter by event
    if params[:event_id].present?
      lines = lines.where(event_id: params[:event_id])
    end

    # Filter by league
    if params[:league_key].present?
      lines = lines.joins(event: :league).where(leagues: { key: params[:league_key] })
    end

    # Filter by bookmaker (default to BetStack consensus line)
    bookmaker_key = params[:bookmaker_key] || 'betstack'
    lines = lines.joins(:bookmaker).where(bookmakers: { key: bookmaker_key })

    # Filter by date
    if params[:date].present?
      begin
        date = Date.parse(params[:date])
        lines = lines.where(events: { commence_time: date.all_day })
      rescue ArgumentError
        # Invalid date, ignore filter
      end
    end

    lines = lines.order('events.commence_time ASC')

    render_collection(lines, :api_json)
  end
end

