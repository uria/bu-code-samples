require_dependency 'rssfeed'

class Community::GeneralController < ApplicationController
  caches_action :rss

  def rss
    rss = RssFeed.new
    rss.title = "Training Connection Community Feed"
    rss.link = url_for(:controller => 'logs', :action => 'index')
    rss.description = "Training Connection Community Feed. Ten last journals, programs and photos."
    rss.language = 'en-us'

    #los logs de cada usuario
    sessions = TrainingSession.find(:all, :limit => 15, :conditions => 'private = FALSE', :order => "training_sessions.created_at DESC", :include => [:user]) || []
    photos = Photo.find(:all, :limit => 10, :conditions => 'private = FALSE', :order => 'photos.created_at DESC', :include => [:user]) || []
    programs = Program.find(:all, :limit => 10, :conditions => 'private = FALSE', :order => 'programs.created_at DESC',  :include => [:user]) || []

    rss.items = (sessions+photos+programs).sort{|a,b| b.created_at <=> a.created_at}.collect do |s|
      prefix, url = case(s)
        when Photo:
          ["PHOTO", url_for(:controller => '/journal/photos', :action => 'show', :log_name => s.user.login, :id => s.id)]
        when Program:
          ["PROGRAM", url_for(:controller => '/journal/programs', :action => 'show', :log_name => s.user.login, :id => s.id)]
        else
          ["LOG", url_for(:controller => '/journal/log', :action => 'show', :log_name => s.user.login, :id => s.id)]
        end
      RssItem.new(url, "#{prefix} - #{s.user.login} - #{s.title}",url,'', s.created_at)
    end
    rss.lastBuildDate = Time.now

    render :partial => '/shared/rss', :object => rss
  end
end
