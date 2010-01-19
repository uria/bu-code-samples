class LogSweeper < ActionController::Caching::Sweeper
  observe TrainingSession, Comment

  def after_save(record)
    case(record)
      when TrainingSession:
        expire_pdf_csv(record.user, record.id)
        expire_session_data(record.user, record.id)
        expire_log_index(record.user)
        expire_community_logs
      when Comment:
        expire_session_comments(record.commentable.user, record.commentable_id)
        expire_log_index(record.commentable.user)
        expire_community_logs
    end
  end

  def after_destroy(record)
    case(record)
      when TrainingSession:
        expire_pdf_csv(record.user, record.id)
        expire_session_data(record.user, record.id)
        expire_session_comments(record.user, record.id)
        expire_log_index(record.user)
        expire_community_logs
      when Comment:
        expire_session_comments(record.commentable.user, record.commentable_id)
        expire_log_index(record.commentable.user)
        expire_community_logs
    end
  end

#############
private
#############

  def expire_log_index(user)
    expire_fragment(Regexp.new("#{user.login}/log/index/.*"))
  end

  def expire_pdf_csv(user, session_id)
    expire_action(:controller => "/journal/log", :action => %w(pdf csv), :id => session_id, :log_name => user.login)
  end

  def expire_session_data(user, session_id)
    expire_fragment(:controller => '/journal/log', :action => 'show', :id => session_id, :log_name => user.login, :part => 'data')
  end

  def expire_session_comments(user, session_id)
    expire_fragment(:controller => '/journal/log', :action => 'show', :id => session_id, :log_name => user.login, :part => 'comments')
  end

  def expire_community_logs
    expire_fragment(:controller => '/community/logs', :action => 'index', :part => 'last_entries')
    expire_fragment(Regexp.new("community/page/.*last_entries.*"))
  end
end