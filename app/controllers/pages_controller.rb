class PagesController < ActionController::Base
  # Include session support for user authentication
  include ActionController::Cookies
  
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
    @user = nil
    @logged_in = false
    # Check for message params from redirects
    @message_success = params[:success]
    @message_error = params[:error]
  end
  
  # POST /account/login - Authenticate with email + API key
  def login
    email = normalize_email(params[:email])
    api_key = params[:api_key]&.strip
    
    @user = User.find_by(email: email, api_key: api_key)
    
    if @user && @user.active? && @user.deleted_at.nil?
      @logged_in = true
      cookies.signed[:user_id] = { value: @user.id, expires: 1.hour.from_now }
      @message_success = "Welcome back!"
      render :account
    else
      @logged_in = false
      @message_error = "Invalid email or API key. Please check your credentials."
      render :account
    end
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
      cookies.delete(:user_id) # Log them out, they need to use new key
      redirect_to account_path(success: "New API key generated! Check your email for the new key.")
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

