class Journal::ProfileController < ApplicationController
  layout 'log'

  def show
  	@user = log_owner
  	@profile = @user.user_profile
		@buttons = write_permission?
  end

  def edit
    if request.get?
      @user = current_user
      @profile = @user.user_profile
      @tags = @user.tag_names.join(' ')
    else
      @user = current_user
      @profile = @user.user_profile
      @tags = params[:tags]
      if @profile.update_attributes(params[:profile])
				@user.tag(@tags.downcase, {:separator => /[\s,;:]+/, :clear => true})
				flash[:notice] = "Profile updated."
				redirect_to :action=>:show
      else
        flash[:error] = "Error updating profile."
      end
    end
  end

  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter
  before_filter :write_permission_filter, :only=>[:edit]
end
