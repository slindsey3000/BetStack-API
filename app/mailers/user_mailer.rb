class UserMailer < ApplicationMailer
  default from: 'BetStack Support <support@betstack.dev>'
  
  # API Key confirmation email
  def api_key_created(user)
    @user = user
    @api_key = user.api_key
    @edge_url = 'https://api.betstack.dev'
    @production_url = 'https://betstack-45ae7ff725cd.herokuapp.com'
    @docs_url = 'https://betstack-45ae7ff725cd.herokuapp.com'
    
    mail(
      to: @user.email,
      subject: 'Your BetStack API Key - Start Building'
    )
  end
  
  # Email verification
  def verify_email(user, verification_token)
    @user = user
    @verification_url = "https://betstack-45ae7ff725cd.herokuapp.com/verify?token=#{verification_token}"
    
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

