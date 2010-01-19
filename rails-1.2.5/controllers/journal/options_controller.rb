class Journal::OptionsController < ApplicationController
  layout 'log'

  def index
  end

  def avatar
    if request.get?
      @user = log_owner
    else
      @user = log_owner
      @user.password = ''
      @user.avatar_image =  params[:user][:avatar_image]
      if @user.save
        flash[:notice] = "Your avatar was uploaded succesfully."
        redirect_to :action=>:index
      else
        flash[:notice] = "Error saving avatar."
      end
    end
  end

  def units
    @user = log_owner
    if request.post?
      @user.password = ''
      @user.metric_system = params[:user][:metric_system]
      if @user.save
        flash[:notice] = "Now using "+(params[:user][:metric_system]=="true"?"metric":"imperial")+ " system";
        redirect_to :action => :index
      end
    end
  end

  def privacy
    @user = log_owner
    if request.post?
      @user.password = ''
      @user.private_default = params[:user][:private_default]
      if @user.save
        flash[:notice] = "Now making entries "+(params[:user][:private_default]=="true"?"private":"public")+ " by default.";
        redirect_to :action => :index
      end
    end
  end

  def password
    if request.post?
      #Comprobar old password
      @user = User.authenticate(log_owner.login, params[:old_password])
      unless @user.nil?
        @user.password = params[:new_password]
        @user.password_confirmation = params[:new_password_confirmation]
        if @user.save
          flash[:notice] = "Password changed successfully."
          redirect_to :action => :index
        end
      else
        @user = User.new
        @user.errors.add_to_base("Old password is incorrect.")
      end
    end
  end

  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter

  #Comprueba que el usuario actual es el dueño del log
  before_filter :write_permission_filter

end
