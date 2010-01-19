# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency 'authenticated_system'
require_dependency 'access_control'

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include AuthenticatedSystem
  include AccessControl
  model :user

private

  def check_messages_periodically
    check_messages if logged_in? && !session.nil? && (session[:messages_checked_at].nil? || session[:messages_checked_at] < 5.minutes.ago)
  end

  def check_messages
      session[:messages_checked_at] = Time.now
      session[:new_messages] = current_user.new_messages_count
  end

  before_filter :login_from_cookie
  before_filter :check_messages_periodically
end
