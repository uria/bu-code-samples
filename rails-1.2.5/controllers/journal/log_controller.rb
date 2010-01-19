require_dependency 'rssfeed'
require_dependency 'unit_conversion'
require_dependency 'comments'
require_dependency 'trial'

class Journal::LogController < ApplicationController
  include UnitConversion
  include Comments
#  include Trial

  layout 'log', :except => [:rss, :csv, :pdf]

  caches_action :pdf, :csv, :rss
  cache_sweeper :log_sweeper, :only => [:new, :edit, :delete, :new_comment, :edit_comment, :delete_comment]
  cache_sweeper :rss_sweeper, :only => [:new, :edit, :delete]

  #Lista las entradas de un determinado periodo
  def list_date
    #Si es el dueo del log poner un botn para que pueda aadir sesiones
    @buttons = write_permission?

    conditions = "user_id=#{log_owner.id}"

    initial_date = sprintf("%d-%d-%d", params[:year], params[:month]||1, params[:day]||1)
    if params[:month].nil?
      final_date = sprintf("%d-01-01", params[:year].to_i+1)
      conditions << " AND done_on >= '#{initial_date}' AND done_on < '#{final_date}'"
    elsif params[:day].nil?
      final_date = sprintf("%d-%d-01", params[:year].to_i+(params[:month].to_i==12?1:0), (params[:month].to_i==12?1:params[:month].to_i+1))
      conditions << " AND done_on >= '#{initial_date}' AND done_on < '#{final_date}'"
    else
      conditions << " AND done_on = '#{initial_date}'"
    end

    conditions << " AND private = FALSE" unless write_permission?

    #Listar las sesiones de entrenamiento entre las fechas dispuestas
    @pages,  @ses = paginate(:training_sessions,
              :per_page =>15,
                 :conditions => conditions,
                 :order => 'done_on DESC, id DESC')

     render "journal/log/index"
  end

  #Lo que vemos al llegar a un blog
  def index
    unless read_fragment("#{log_owner.login}/log/index/#{params[:page]||1}/#{write_permission?}")
      #Si es el dueo del log poner un botn para que pueda aadir sesiones
      @buttons = write_permission?

      conditions = "user_id = #{log_owner.id}"
      conditions << " AND private = FALSE" unless write_permission?

      #Listar las ultimas sesiones de entrenamiento (paginar)
      @pages,  @ses = paginate(:training_sessions,
                  :per_page =>15,
                  :conditions => conditions,
                  :order => 'done_on DESC, id DESC')
    end
  end

  #Muestra una sesion de entrenamiento
  def show
    unless read_fragment(:action => 'show', :part => 'session')
      #debe llamarse @ses como en valid_session, si no cascar la cach
      @ses = get_object(:include => [{:training_sets => :exercise}])
    end
    unless read_fragment(:action => 'show', :part => 'comments')
      @comments = Comment.find(:all, :conditions =>["commentable_type = 'TrainingSession' AND commentable_id = ?", params[:id]], :include => [:user])
    end
    @buttons = write_permission?
  end

  #Borra una sesion de entrenamiento
  def delete
    if request.post?
      get_object.destroy
      flash[:notice] = "Training session deleted."
    end
    redirect_to :action=>'index'
  end

  #Para editar una sesion de entrenamiento
  def edit
    if request.get? #GET
      @ses = get_object
    else  #POST
      @ses = get_object
      begin
        TrainingSession.transaction do
          @ses.training_sets.clear #hace un delete y un update por cada TS, cambiar por un delete where session_id=x
          @ses.build_training_sets_from_hash!(params[:set],current_user) if params[:set]
          if @ses.update_attributes(params[:ses])
            flash[:notice] = "Training session data updated."
          else
            raise Exception, "Error saving training session, rolling back"
          end
        end
      rescue
        log_error($!) if logger
        flash[:error] = "Error saving training session."
      ensure
        redirect_to(:action => "index")
      end
    end
  end

  #Para aadir una nueva sesion de entrenamiento
  def new
    if request.get? #GET
        #La sesin
        @ses = TrainingSession.new
        @ses.private = log_owner.private_default
        #Los programas
        progs = current_user.programs.find_all
        @programs = [["None", -1]]
        progs.each do |p| @programs << [p.title, p.id] end
    else #POST
        begin
          #utilizar los parametros del form
          @ses = TrainingSession.new(params[:ses])
          #asignar la nueva sesion de entrenamiento al usuario que est logueado
          @ses.user = current_user
          @ses.program = current_user.programs.find(params[:program][:id]) if params[:program][:id] && params[:program][:id].to_i > 0
          TrainingSession.transaction do
            #salvar la sesion de entrenamiento
            @ses.build_training_sets_from_hash!(params[:set],current_user) if params[:set]
            @ses.save!
          end #transaction
          flash[:notice] = "Training session saved."
        rescue
          log_error($!) if logger
          flash[:error] = "Error saving training session."
        ensure
          redirect_to(:action => "index")
        end
    end
  end

  def rss
    rss = RssFeed.new
    rss.title = "#{log_owner.login}'s training log.".capitalize
    rss.link = url_for(:action => :index)
    rss.description = "#{log_owner.login}'s training log.".capitalize
    rss.language = 'en-us'

    #los logs de cada buddy
    sessions = TrainingSession.find(:all,
        :limit => 10,
        :conditions => ["user_id = :user_id AND private = FALSE", {:user_id => log_owner.id}],
        :order => "created_at DESC") || []

    photos = log_owner.photos.find(:all, :limit => 10, :conditions => 'private = FALSE', :order => 'created_at DESC') ||[]
    programs = log_owner.programs.find(:all, :limit => 10, :conditions => 'private = FALSE', :order => 'updated_at DESC') ||[]

    rss.items = (sessions+photos+programs).sort{|a,b| b.created_at <=> a.created_at}.collect do |s|
      prefix, url = case(s)
        when Photo:
          ["PHOTO - ", url_for(:controller => 'photos', :action => 'show', :log_name => log_owner.login, :id => s.id)]
        when Program:
          ["PROGRAM - ", url_for(:controller => 'programs', :action => 'show', :log_name => log_owner.login, :id => s.id)]
        else
          ["LOG - ", url_for(:controller => 'log', :action => 'show', :log_name => log_owner.login, :id => s.id)]
        end
      RssItem.new(url, prefix + s.title,url,'', s.created_at)
    end
    rss.lastBuildDate = (sessions.any? ? sessions[0].created_at : Time.parse("1980/12/3"))

    render :partial => '/shared/rss', :object => rss
  end

  def pdf
    @ses = [get_object(:include => [{:training_sets => :exercise}])] #as an array to use render :partial, :collection => @ses
    @filename = "(" + @ses[0].done_on.to_s + ") " + @ses[0].title
    @filename = @filename.gsub(/[\s\/-]+/, '_').gsub(/[^0-9a-zA-Z_]/, '')
  end

  def csv
    #Session to export
    @ses = get_object(:include => [{:training_sets => :exercise}])

    #Filename
    filename = "(" + @ses.done_on.to_s + ") " + @ses.title
    filename = filename.gsub(/[\s\/-]+/, '_').gsub(/[^0-9a-zA-Z_]/, '')

    #Export
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
    render :partial => 'csv', :object => @ses
  end

  def export
    if request.post?
      from = Time.gm(params[:date]["from(1i)"],params[:date]["from(2i)"],params[:date]["from(3i)"])
      to = Time.gm(params[:date]["to(1i)"],params[:date]["to(2i)"],params[:date]["to(3i)"])
      @filename = log_owner.login + "_training_sessions";
      @filename = @filename.gsub(/[^0-9a-zA-Z_]/, '')
      conditions = "done_on >= '#{from.to_formatted_s :db}' AND done_on <= '#{to.to_formatted_s :db}'"
      conditions << " AND private = FALSE" unless write_permission?
      @ses = log_owner.training_sessions.find(:all, :conditions => conditions, :order => "done_on ASC")
      if @ses.length == 0
          flash[:warning] = "No training sessions within selected dates."
      elsif params[:export][:format] == 'PDF'
        render :action => :pdf, :layout => false
      else
        response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
        response.headers['Content-Disposition'] = "attachment; filename=#{@filename}.csv"
        render :partial => 'csv', :collection => @ses
      end
    end
  end

  def ganttsecret
  end
### PRIVATE ###
private
  #fetch de la BD la session de entrenamiento pedida
  def get_object(*args)
    if args.size == 0
      @ses ||= log_owner.training_sessions.find(params[:id])
    else
      log_owner.training_sessions.find(params[:id], *args)
    end
  end

  #Si la session no es de este log, redirigir
  def valid_training_session
    begin
    #Lanza una excepcin si la sesion no existe
      #debe llamarse @ses como en show, si no cascar la cach
      @ses = get_object
      if @ses.private && !write_permission?
        flash[:error] = 'Session does not exist or is private.'
        redirect_to :action => 'index'
      end
    rescue
      flash[:error] = 'Session does not exist.'
      redirect_to :action => 'index'
    end
  end

  def name_controller
    @controller_name = "Training log"
  end

  def unit_conversion
    params[:set].each_value do |exercise|
      exercise.each_value do |set|
        set['weight'] = weight_string_to_f(set['weight'])
        set['intensity'] = intensity_string_to_f!(set['intensity'])
      end
    end if params[:set]
  end

  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter

  #Comprueba que la sesion de entrenamiento existe y est asociada con el log
  before_filter :valid_training_session, :only => [:show, :edit, :delete, :pdf, :csv]

  #Comprueba que el usuario actual es el dueo del log
  before_filter :write_permission_filter, :only => [:new, :edit, :delete]

  before_filter :name_controller

  #Convertir pesos de kg a lbs cuando sea necesario
  before_filter :unit_conversion, :only => [:new, :edit]

end
