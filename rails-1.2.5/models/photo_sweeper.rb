class PhotoSweeper < ActionController::Caching::Sweeper
  observe Photo, Comment

  def after_save(record)
    case(record)
      when Comment:
        expire_photo_comments(record.commentable.user, record.commentable_id)
        expire_community_photos
      when Photo:
        expire_community_photos
    end
  end

  def after_delete(record)
    case(record)
      when Comment:
        expire_photo_comments(record.commentable.user, record.commentable_id)
        expire_community_photos
      when Photo:
        expire_community_photos
    end
  end

#############
private
#############
  def expire_photo_comments(user, session_id)
    expire_fragment(:controller => '/journal/photos', :action => 'show', :id => session_id, :log_name => user.login, :part => 'comments')
  end

  def expire_community_photos
    expire_fragment(:controller => '/community/photos', :action => 'index')
  end
end