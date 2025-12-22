class PagesController < ActionController::Base
  # Include session support for user authentication
  include ActionController::Cookies
  
  # Skip CSRF verification - requests come from api.betstack.dev (Cloudflare)
  # but hit betstack-xxx.herokuapp.com, causing origin mismatch
  # Security is maintained via signed cookies for authentication
  skip_forgery_protection
  
  # Use pages layout for all actions
  layout "pages"
  
  # GET / - Landing page
  def home
    @sports_count = Sport.count
    @leagues_count = League.count
    @events_count = Event.count
    @bookmakers_count = Bookmaker.count
  end
  
  # GET /docs - API Documentation
  def docs
    @sports = Sport.where(active: true).order(:name)
    @leagues = League.includes(:sport).where(active: true).order(:name)
    @bookmakers = Bookmaker.where(active: true).order(:name)
  end
  
  # GET /account - Account management page
  def account
    @user = User.find_by(id: cookies.signed[:user_id])
    @logged_in = @user.present?
    # Check for message params from redirects
    @message_success = params[:success]
    @message_error = params[:error]
  end
  
  # POST /account/login - Authenticate with email + password
  def login
    email = normalize_email(params[:email])
    password = params[:password]
    
    @user = User.active.find_by(email: email)
    
    if @user && @user.authenticate(password)
      @logged_in = true
      cookies.signed[:user_id] = { value: @user.id, expires: 1.hour.from_now }
      @message_success = "Welcome back!"
      render :account
    else
      @logged_in = false
      @message_error = "Invalid email or password. Please check your credentials."
      render :account
    end
  end
  
  # POST /account/logout - Log out
  def logout
    cookies.delete(:user_id)
    redirect_to account_path(success: "You have been logged out.")
  end
  
  # GET /forgot-password - Forgot password form
  def forgot_password
    @message_success = params[:success]
    @message_error = params[:error]
  end
  
  # POST /forgot-password - Send password reset email
  def send_password_reset
    email = normalize_email(params[:email])
    @user = User.active.find_by(email: email)
    
    if @user
      @user.generate_password_reset_token!
      UserMailer.password_reset(@user).deliver_later
    end
    
    # Always show success message to prevent email enumeration
    redirect_to forgot_password_path(success: "If an account exists with that email, you'll receive a password reset link shortly.")
  end
  
  # GET /reset-password - Reset password form (with token)
  def reset_password
    @token = params[:token]
    @user = User.find_by(password_reset_token: @token)
    
    if @user.nil? || !@user.password_reset_valid?
      redirect_to forgot_password_path(error: "This password reset link is invalid or has expired. Please request a new one.")
    end
  end
  
  # POST /reset-password - Process password reset
  def process_password_reset
    @token = params[:token]
    @user = User.find_by(password_reset_token: @token)
    
    if @user.nil? || !@user.password_reset_valid?
      redirect_to forgot_password_path(error: "This password reset link is invalid or has expired. Please request a new one.")
      return
    end
    
    if params[:password].blank? || params[:password].length < 6
      @message_error = "Password must be at least 6 characters."
      render :reset_password
      return
    end
    
    if params[:password] != params[:password_confirmation]
      @message_error = "Passwords don't match."
      render :reset_password
      return
    end
    
    @user.password = params[:password]
    @user.clear_password_reset!
    
    UserMailer.password_changed(@user).deliver_later
    
    redirect_to account_path(success: "Your password has been reset! You can now log in with your new password.")
  end
  
  # POST /account/update - Update profile
  def update_profile
    @user = User.find_by(id: cookies.signed[:user_id])
    
    unless @user
      redirect_to account_path(error: "Please log in first.") and return
    end
    
    new_email = params[:email]&.strip
    new_phone = params[:phone_number]&.strip
    
    changes_made = []
    
    if new_email.present? && normalize_email(new_email) != @user.email
      @user.email = normalize_email(new_email)
      changes_made << "email"
    end
    
    if new_phone.present? && normalize_phone(new_phone) != @user.phone_number
      @user.phone_number = normalize_phone(new_phone)
      changes_made << "phone number"
    end
    
    if changes_made.any? && @user.save
      # Send confirmation email
      UserMailer.profile_updated(@user, changes_made).deliver_later
      @message_success = "Profile updated! A confirmation email has been sent."
    elsif changes_made.empty?
      @message_warning = "No changes detected."
    else
      @message_error = "Failed to update profile: #{@user.errors.full_messages.join(', ')}"
    end
    
    @logged_in = true
    render :account
  end
  
  # POST /account/change-password - Change password
  def change_password
    @user = User.find_by(id: cookies.signed[:user_id])
    
    unless @user
      redirect_to account_path(error: "Please log in first.") and return
    end
    
    current_password = params[:current_password]
    new_password = params[:new_password]
    confirm_password = params[:confirm_password]
    
    # Verify current password
    unless @user.authenticate(current_password)
      @message_error = "Current password is incorrect."
      @logged_in = true
      render :account
      return
    end
    
    # Validate new password
    if new_password.blank? || new_password.length < 6
      @message_error = "New password must be at least 6 characters."
      @logged_in = true
      render :account
      return
    end
    
    if new_password != confirm_password
      @message_error = "New passwords don't match."
      @logged_in = true
      render :account
      return
    end
    
    @user.password = new_password
    if @user.save
      UserMailer.password_changed(@user).deliver_later
      @message_success = "Password changed successfully!"
    else
      @message_error = "Failed to change password."
    end
    
    @logged_in = true
    render :account
  end
  
  # POST /account/regenerate_key - Generate new API key
  def regenerate_key
    @user = User.find_by(id: cookies.signed[:user_id])
    
    unless @user
      redirect_to account_path(error: "Please log in first.") and return
    end
    
    # Generate new key
    loop do
      @user.api_key = SecureRandom.hex(32)
      break unless User.where.not(id: @user.id).exists?(api_key: @user.api_key)
    end
    
    if @user.save
      # Send email with new key
      UserMailer.api_key_regenerated(@user).deliver_later
      @message_success = "New API key generated! Check your email for the new key."
      @logged_in = true
      render :account
    else
      @message_error = "Failed to regenerate API key."
      @logged_in = true
      render :account
    end
  end
  
  # POST /account/delete - Soft delete account
  def delete_account
    @user = User.find_by(id: cookies.signed[:user_id])
    
    unless @user
      redirect_to account_path(error: "Please log in first.") and return
    end
    
    # Soft delete: invalidate key and mark as deleted
    @user.update!(
      active: false,
      deleted_at: Time.current,
      api_key: "deleted_#{SecureRandom.hex(16)}" # Invalidate the key
    )
    
    # Send confirmation email
    UserMailer.account_deleted(@user).deliver_later
    
    cookies.delete(:user_id)
    redirect_to account_path(success: "Your account has been deleted. Your API key is now invalid. You can sign up again anytime at betstack.dev.")
  end
  
  private
  
  def normalize_email(email)
    return nil unless email.present?
    
    normalized = email.downcase.strip
    local_part, domain = normalized.split('@', 2)
    return normalized unless domain
    
    # Remove plus addressing
    local_part = local_part.split('+').first
    
    # Remove periods for Gmail
    if domain =~ /^(gmail\.com|googlemail\.com)$/
      local_part = local_part.gsub('.', '')
    end
    
    "#{local_part}@#{domain}"
  end
  
  def normalize_phone(phone)
    return nil unless phone.present?
    phone.gsub(/\D/, '')
  end
end
