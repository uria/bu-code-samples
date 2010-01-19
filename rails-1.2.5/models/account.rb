class Account < ActionMailer::Base
  @@from = 'info@lifterlog.com'

  def welcome(user, password,  sent_at = Time.now)
    @from = @@from
    @recipients = user.email
    @sent_on = @sent_at
    @subject = "Welcome to Charles Staley's Training Connection. Login information."
    @body = {:login => user.login, :password => password}
    content_type("text/html")
  end

  def trial_expiry(user, sent_at = Time.now)
    @from = @@from
    @recipients = user.email
    @sent_on = @sent_at
    @subject = 'Your Training Connection trial period expired.'
    @body = {:login => user.login}
    content_type("text/html")
  end

  def paying_thanks(user, sent_at = Time.now)
    @from = @@from
    @recipients = user.email
    @sent_on = @sent_at
    @subject = 'Thank your for upgrading you Training Connection account.'
    @body = {}
    content_type("text/html")
  end

  def paying_error(email_address, sent_at = Time.now)
    @from = @@from
    @recipients = email_address
    @sent_on = @sent_at
    @subject = 'There was an error processing your payment. Our administrator has been notified.'
    @body = {}
    content_type("text/html")
  end

  def forgot_password(user, sent_at = Time.now)
    @from = @@from
    @recipients = user.email
    @sent_on = @sent_at
    @subject = 'Change your password.'
    @body = {:user => user}
    content_type("text/html")
  end
end
