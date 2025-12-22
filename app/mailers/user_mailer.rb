class UserMailer < ApplicationMailer
  default from: 'BetStack Support <support@betstack.dev>'
  
  # API Key confirmation email
  def api_key_created(user)
    @user = user
    @api_key = user.api_key
    @edge_url = 'https://api.betstack.dev'
    @docs_url = 'https://api.betstack.dev/docs'
    
    mail(
      to: @user.email,
      subject: 'Your BetStack API Key - Start Building'
    )
  end
  
  # API Key regenerated
  def api_key_regenerated(user)
    @user = user
    @api_key = user.api_key
    @edge_url = 'https://api.betstack.dev'
    @docs_url = 'https://api.betstack.dev/docs'
    
    mail(
      to: @user.email,
      subject: 'Your New BetStack API Key'
    )
  end
  
  # Profile updated confirmation
  def profile_updated(user, changes_made)
    @user = user
    @changes_made = changes_made
    
    mail(
      to: @user.email,
      subject: 'Your BetStack Profile Was Updated'
    )
  end
  
  # Account deleted confirmation
  def account_deleted(user)
    @user = user
    
    mail(
      to: @user.email,
      subject: 'Your BetStack Account Has Been Deleted'
    )
  end
  
  # Email verification
  def verify_email(user, verification_token)
    @user = user
    @verification_url = "https://api.betstack.dev/verify?token=#{verification_token}"
    
    mail(
      to: @user.email,
      subject: 'Verify Your BetStack Email'
    )
  end
  
  # Test email
  def test_email(to_email)
    @timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')
    
    mail(
      to: to_email,
      subject: 'BetStack API - Test Email'
    )
  end
end

