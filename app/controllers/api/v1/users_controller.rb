# API controller for Users
# Provides endpoints to manage API users

class Api::V1::UsersController < Api::V1::BaseController
  # GET /api/v1/users
  # Returns all users
  def index
    users = User.order(created_at: :desc)
    render_collection(users, :api_json)
  end

  # GET /api/v1/users/:id
  # Returns a single user (without API key for security)
  def show
    user = User.find_by(id: params[:id])
    
    if user
      render_resource(user, :api_json)
    else
      render_not_found("User")
    end
  end

  # POST /api/v1/users
  # Creates a new user with auto-generated API key
  # Valid for 100 years by default
  # Params: email, phone_number, address (optional)
  def create
    user = User.new(user_params)
    
    # Set default times (now and 100 years from now)
    user.start_time ||= Time.current
    user.end_time ||= 100.years.from_now
    user.active = true

    if user.save
      render json: user.api_json_with_key, status: :created
    else
      render json: {
        error: "Failed to create user",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/users/:id
  # Updates a user (can change start_time, end_time, active status, etc.)
  # Params: start_time, end_time, active, email, phone_number, address
  def update
    user = User.find_by(id: params[:id])
    
    unless user
      return render_not_found("User")
    end

    if user.update(user_params)
      render_resource(user, :api_json)
    else
      render json: {
        error: "Failed to update user",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:email, :phone_number, :address, :start_time, :end_time, :active)
  end
end
