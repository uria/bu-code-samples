class RssSweeper < ActionController::Caching::Sweeper
  observe TrainingSession, Program, Photo

  def after_save(record)
    expire_community_rss
    expire_user_rss(record.user)
  end

  def after_destroy(record)
    expire_community_rss
    expire_user_rss(record.user)
  end

#############
private
#############

  def expire_community_rss
    expire_action(:controller => "/community/general", :action => 'rss')
  end

  def expire_user_rss(user)
    expire_action(:controller => "/journal/log", :action => 'rss', :log_name => user.login)
  end

end