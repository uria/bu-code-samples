class CommunityController < ApplicationController
  layout 'community'

  def users
    if params[:tagged]
      @pages,	@users = paginate_tagged('User', params[:tagged], :per_page =>15, :conditions => 'is_public = true', :order => 'id DESC')
	else #Listar todos los programas (paginar)
      @pages,	@users = paginate(:users, :per_page =>15, :conditions => 'is_public = true',:order => 'id DESC')
    end
  end

  def programs
    authorize_copy
  	
  	if params[:tagged]
      @pages,	@progs = paginate_tagged('Program', params[:tagged], :per_page =>15, :order => 'programs.id DESC', :include => :user)
	else #Listar todos los programas (paginar)
      @pages,	@progs = paginate(:programs, :per_page =>15, :order => 'programs.id DESC', :include => :user)
    end
  end
end
