class ProgramSweeper < ActionController::Caching::Sweeper
  observe Program, Comment

  def after_save(record)
    case(record)
      when Program
        expire_pdf_csv(record.user, record.id)
        expire_program_data(record.user, record.id)
        expire_program_index(record.user)
        expire_community_programs
      when Comment
        expire_program_comments(record.commentable.user, record.commentable_id)
        expire_program_index(record.commentable.user)
        expire_community_programs
    end
  end

  def after_destroy(record)
    case(record)
      when Program
        expire_pdf_csv(record.user, record.id)
        expire_program_data(record.user, record.id)
        expire_program_index(record.user)
        expire_community_programs
      when Comment
        expire_program_comments(record.commentable.user, record.commentable_id)
        expire_program_index(record.commentable.user)
        expire_community_programs
    end
  end

#############
private
#############
  def expire_program_index(user)
    expire_fragment(Regexp.new("#{user.login}/programs/index/.*"))
    expire_fragment(Regexp.new("#{user.login}/programs/tag_cloud/.*"))
  end
  def expire_pdf_csv(user, id)
    expire_action(:controller => "/journal/programs", :action => %w(pdf csv), :id => id, :log_name => user.login)
  end

  def expire_program_data(user, program_id)
    expire_fragment(:controller => '/journal/programs', :action => 'show', :id => program_id, :log_name => user.login, :part => 'data')
  end

  def expire_program_comments(user, program_id)
    expire_fragment(:controller => '/journal/programs', :action => 'show', :id => program_id, :log_name => user.login, :part => 'comments')
  end

  def expire_community_programs
    expire_fragment(:controller => '/community/programs', :action => 'index')
  end
end