require_dependency 'rssfeed'

class Journal::BuddiesController < ApplicationController
  layout 'log', :except => [:add]

  def index
    #Si es el dueño del log poner un botón para que pueda modificar buddies
    @buttons = write_permission?
    @sessions = buddies_last_training_sessions
  end

  def listing
  #Si es el dueño del log poner un botón para que pueda modificar buddies
    @buttons = write_permission?

    #Listar los buddies (paginar)
    @pages,  @buddies = paginate(:users,
        :joins => "INNER JOIN user_buddies as ub ON users.id = ub.user_id INNER JOIN users as b ON ub.buddy_id = b.id",
        :per_page => 15,
        :conditions => ["users.id = ?", log_owner.id],
        :order => 'b.login ASC')
  end

  def add
    begin
      if params[:name]
        log_owner.add_buddy!(params[:name])
        flash.now[:notice] = "#{params[:name]} added to your buddies."
      end
    rescue Exception => e
      flash.now[:notice] = e.to_s
    ensure
      render :partial => '/shared/notices'
    end
  end

  def delete
    if request.post? && params[:name]
      begin
        log_owner.delete_buddy!(params[:name])
        flash[:notice] = "#{params[:name]} has been removed from your buddies."
      rescue Exception => e
        flash[:error] = "Error removing #{params[:name]} from your buddies."
      end
    end
    redirect_to :action => :listing
  end

  def rss
    rss = RssFeed.new
    rss.title = "#{log_owner.login}'s buddies.".capitalize
    rss.link = url_for(:action => :index)
    rss.description = "#{log_owner.login}'s buddies training logs.".capitalize
    rss.language = 'en-us'

    #los logs de cada buddy
    sessions = buddies_last_training_sessions
    photos = buddies_last_photos
    programs = buddies_last_programs

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

private
  def buddies_last_training_sessions(limit = 15)
    TrainingSession.find(:all, :limit => limit, :conditions => ["private = FALSE AND user_id in (select buddy_id from user_buddies where user_id = #{log_owner.id})"], :order => 'training_sessions.updated_at DESC', :include => :user)
  end

  def buddies_last_programs(limit = 15)
    Program.find(:all, :limit => limit, :conditions => ["private = FALSE AND user_id in (select buddy_id from user_buddies where user_id = #{log_owner.id})"], :order => 'programs.updated_at DESC', :include => :user)
  end

  def buddies_last_photos(limit = 15)
    Photo.find(:all, :limit => limit, :conditions => ["private = FALSE AND user_id in (select buddy_id from user_buddies where user_id = #{log_owner.id})"], :order => 'photos.updated_at DESC', :include => :user)
  end

  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter

  #Comprueba que el usuario actual es el dueño del log
  before_filter :write_permission_filter, :only => [:add, :delete]
end
