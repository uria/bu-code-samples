class AccountController < ApplicationController
  layout 'public'

  session :off, :only => %w(status_promotion purchase)

  def index
    redirect_to(:action => 'signup') unless logged_in? or User.count > 0
  end

  def login
    return unless request.post?
    reset_session
    self.current_user = User.authenticate(params[:login], params[:password])
    if current_user
      if params[:remember_me]
        cookies[:k1] = {:value => current_user.id.to_s, :expires => Time.now + (3600*24*1825)}
        cookies[:k2] = {:value => current_user.crypted_password, :expires => Time.now + (3600*24*1825)}
      end
      redirect_back_or_default :controller => "/journal/log", :action => "index", :log_name => current_user.login
      flash[:notice] = "Logged in successfully."
    else
      flash[:error] = "Incorrect password. Try again."
    end
  end

  def signup
    @user = User.new(params[:user])
    @user.errors.add_to_base("You must agree Terms of Service in order to register.") if !params[:agreed_tos] && request.post?

    if request.post? and params[:agreed_tos] and @user.save
      #Comment next line if activation enabled
      self.current_user = @user
      redirect_back_or_default :controller => "/journal/log", :action => "index", :log_name => @user.login
      flash[:notice] = "Thanks for signing up!"
      Account.deliver_welcome(@user, params[:user][:password])
    end
  end

  def logout
    self.current_user = nil
    reset_session
    cookies.delete :k1
    cookies.delete :k2
    flash[:notice] = "You have been logged out."
    redirect_to :controller => 'entrance', :action => 'index'
  end

  def forgotpass
    if request.post?
      @user = User.find_by_login(params[:email]) || User.find_by_email(params[:email])
      if @user.nil?
        #Si no hay ningun usuarios con ese login ni ese mail, pues error
        flash.now[:error] = <<-END_OF_STRING
          Login or email not found. Try another or <a href="mailto:beni.asturias@gmail.com">contact the admin</a> if you don't remember neither of them.
          END_OF_STRING
      else
        #mandar el email con el enlace
        Account.deliver_forgot_password(@user)
      end
    end
  end

  def changepass
    @login = params[:login]
    @safeconduct = params[:safeconduct]
    if request.post?
      @user = User.find_by_login(@login)
      if !@user.nil? && @user.crypted_password == @safeconduct
        @user.password = params[:new_password]
        @user.password_confirmation = params[:new_password_confirmation]
        if @user.save
          flash[:notice] = "Password changed successfully."
          redirect_to :controller => 'entrance', :action => 'index'
        end
      else
        @user = User.new
        @user.errors.add_to_base("No password change for you! Is this your last safeconduct you received? <a href='mailto:beni.asturias@gmail.com'>Contact our admin</a>.")
      end
    end
  end

  def thank_you
  end

  ## Invocado por 1shoppingcart
  def status_promotion
    if request.post?
      #Find paying user
      @user = User.find_by_email(params[:email]) || User.find_by_login(params[:username])

      #Log payment
      payment = Payment.new(:user => @user, :ip => request.remote_ip, :parameters => params.delete_if{|k,v| %w{controller action}.include?(k)}.inspect)

      #Promote user status or log an error
      if !@user.nil? && @user.promote_to_paying_status
        payment.success = true
        #Enviar un email al usuario.
        Account.deliver_paying_thanks(@user)
      else
        payment.success = false
        #Enviar un email. Alguien ha pagado y no se le ha puesto de pago.
        Account.deliver_paying_error(params[:email])
        Account.deliver_paying_error("narsil@telecable.es")
      end

      #Log
      payment.save

      render :text => "OK"
    else
      render :nothing => true, :status => 404
    end
  end

  ### Redirects to purchase URL
  def purchase
    redirect_to "http://www.1shoppingcart.com/app/javanof.asp?MerchantID=31593&ProductID=3257357"
  end

end
