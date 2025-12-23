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
  # If user was previously deleted, reactivate with new API key
  # Params: email, phone_number, address (optional)
  def create
    # Check if there's a deleted user with this email that can be reactivated
    deleted_user = User.find_deleted_by_email(params[:email])
    
    if deleted_user
      # Reactivate the deleted user with a new API key and password
      deleted_user.reactivate!(new_phone: params[:phone_number])
      plain_password = deleted_user.plain_password # Capture before it's cleared
      deleted_user.update(api_reason: params[:api_reason]) if params[:api_reason].present?
      
      # Send welcome email with new API key and password
      UserMailer.api_key_created(deleted_user, plain_password).deliver_later
      
      # Notify admin of new signup
      UserMailer.new_signup_notification(deleted_user).deliver_later
      
      # Immediately sync API key to Cloudflare for instant access
      SyncSingleApiKeyJob.perform_later(deleted_user.id)
      
      return render json: {
        success: true,
        message: "Welcome back! Your account has been reactivated. Check your email for your new API key.",
        email: deleted_user.email
      }, status: :created
    end
    
    # Create new user
    user = User.new(user_params)
    
    # Set default times (now and 100 years from now)
    user.start_time ||= Time.current
    user.end_time ||= 100.years.from_now
    user.active = true

    if user.save
      # Capture plain password before it's cleared from memory
      plain_password = user.plain_password
      
      # Send welcome email with API key and password (asynchronously)
      UserMailer.api_key_created(user, plain_password).deliver_later
      
      # Notify admin of new signup
      UserMailer.new_signup_notification(user).deliver_later
      
      # Immediately sync API key to Cloudflare for instant access
      SyncSingleApiKeyJob.perform_later(user.id)
      
      # Return success without API key - user must check email
      render json: {
        success: true,
        message: "Account created! Check your email for your API key.",
        email: user.email
      }, status: :created
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
    params.permit(:email, :phone_number, :address, :api_reason, :start_time, :end_time, :active)
  end
end
