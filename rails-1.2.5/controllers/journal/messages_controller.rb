class Journal::MessagesController < ApplicationController
  layout 'log'

  def index
    @pages,  @messages = paginate( :messages, :per_page =>20,
                                  :conditions => ["recipient_id = ?", current_user.id],
                                  :order => 'sent_at DESC',
                                  :include => :sender)
  end

  def read
    begin
      @message = current_user.messages.find(params[:id])
      @message.opened = true
      @message.save
      check_messages
    rescue
      flash[:error] = "Error reading message. Probably it does not exist."
      redirect_to :action => :index
    end
  end

  def write
    if !request.post?
      @message = Message.new
      @recipient_name = params[:recipient_name] || (write_permission?()?"":log_owner.login)
      @message.content = ''
    else
      @message = Message.new(params[:message])
      @recipient_name = params[:recipient_name]
      @message.recipient = User.find(:first, :conditions => ["login = ?", @recipient_name])
      @message.sender = current_user
      if @message.save
        flash[:notice] = "Message sent."
        if current_user_is_log_owner?
          redirect_to :action=>'index'
        else
          redirect_to :controller =>'log', :action=>'index'
        end
      end
    end
  end

  def reply
    @message = current_user.messages.find(params[:id])
    @recipient_name = @message.sender.login
    @message.subject = "Re: " + @message.subject
    render :action => :write
  end

  def delete
    params[:m].each_pair { |id, delete| current_user.messages.find(id).destroy if delete == 'on' } unless params[:m].nil?
    flash[:notice] = "Messages deleted."
    redirect_to :action=>:index
  end

  before_filter :valid_log_filter
  before_filter :login_required, :only => :write
  before_filter :write_permission_filter, :except => :write
  before_filter :check_messages, :except => :read

end
