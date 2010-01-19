class Community::LogsController < ApplicationController
  layout 'community', :except => 'popular_users'

  def index
    unless read_fragment(:controller => 'logs', :action => 'index', :part => 'last_entries')
      @pages, @users = paginate(:training_sessions, :per_page =>15, :conditions => ['done_on > ? AND private = FALSE', 1.weeks.ago.to_formatted_s(:db)], :order => 'training_sessions.updated_at DESC', :include => :user)
      @cloud_tags = User.tags_count(:raw => true, :limit => 100, :count => '>1', :order => 'tags.name ASC')
    end

    unless read_fragment(:controller => 'logs', :action => 'index', :part => 'wotw')
      @wotw = HighlightedWorkout.find(:first, :conditions => ["since <= ?", Time.now.to_formatted_s(:db)], :order => 'since DESC', :include => [:training_session => [:user]])
    end
  end

  def search
    @tag = params[:tagged]
    @pages,  @users = paginate(:users, :tagged => @tag, :per_page =>15, :order => 'id DESC')
    @cloud_tags = User.find_related_tags(@tag, :raw => true, :limit => 20, :count => '>1')
    @cloud_tags.sort!{|a,b| a['name'] <=> b['name']}
  end

  def popular_users
    since = 1.month.ago
    @users = User.find_by_sql(["select * from users inner join (select buddy_id as user, count(*) as friend_of from user_buddies where friendship_at > ? group by buddy_id order by friend_of desc limit 10) as buddies_count on id = user", since.strftime('%Y-%m-%d')])
  end
end
