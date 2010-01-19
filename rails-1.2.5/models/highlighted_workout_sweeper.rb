class HighlightedWorkoutSweeper < ActionController::Caching::Sweeper
  observe HighlightedWorkout

  def after_save(record)
    expire_community_wotw
  end

  def after_destroy(record)
    expire_community_wotw
  end

#############
private
#############

  def expire_community_wotw
    expire_fragment(:controller => '/community/logs', :action => 'index', :part => 'wotw')
    expire_fragment(Regexp.new("community/page/.*wotw.*"))
  end
end