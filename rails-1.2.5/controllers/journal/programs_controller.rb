require_dependency 'comments'
require_dependency 'trial'

class Journal::ProgramsController < ApplicationController
  include Comments
#  include Trial

  layout 'log', :except => [:csv, :pdf]

  caches_action :pdf, :csv
  cache_sweeper :program_sweeper, :only => [:new, :edit, :copy, :delete, :new_comment, :edit_comment, :delete_comment]
  cache_sweeper :rss_sweeper, :only => [:new, :edit, :copy, :delete]

  #Listar los programas de entrenamiento
  def index
    #Si es el dueo del log poner un botn para que pueda aadir sesiones
    @buttons = write_permission?
    authorize_copy

    conditions = "user_id = #{log_owner.id}"
    conditions << " AND private = FALSE" unless write_permission?

    unless read_fragment("#{log_owner.login}/programs/index/#{params[:page]||1}/#{@buttons}/#{@copy_button}")
      @pages,  @progs = paginate(:programs, :per_page =>15,
                                  :conditions => conditions,
                                  :order => 'programs.created_at DESC', :include => [:tags])
    end

    unless read_fragment("#{log_owner.login}/programs/tag_cloud/#{@buttons}")
      #@cloud_tags = Program.tags_count(:raw => true, :conditions => ["user_id = ?", log_owner.id], :limit => 100, :count => '>1', :order => 'tags.name ASC')
      @cloud_tags = Program.tags_count(:raw => true, :conditions => conditions, :limit => 100, :count => '>1', :order => 'tags.name ASC')
    end
  end

  def search
    #Si es el dueo del log poner un botn para que pueda aadir sesiones
    @buttons = write_permission?
    authorize_copy

    conditions = "user_id = #{log_owner.id}"
    conditions << " AND private = FALSE" unless write_permission?

    @tag = params[:tagged]
    @pages,  @progs = paginate(:programs, :tagged => @tag, :per_page =>15,
                                :conditions => conditions,
                                :order => 'programs.created_at DESC', :include => [:tags])

    #no pueden volver ordenadas alfabeticamente pq ordena por count para limit
    #@cloud_tags = Program.find_related_tags(@tag, :raw => true, :conditions => ["user_id = ?", log_owner.id], :limit => 20, :count => '>1')
    @cloud_tags = Program.find_related_tags(@tag, :raw => true, :conditions => conditions, :limit => 20, :count => '>1')
    @cloud_tags.sort!{|a,b| a['name'] <=> b['name']}
  end

  def show
    authorize_copy
    unless read_fragment(:action => 'show', :part => 'data')
      @program = load_whole_program
    end
    unless read_fragment(:action => 'show', :part => 'comments')
      @comments = Comment.find(:all, :conditions => ["commentable_type = 'Program' AND commentable_id = ?", params[:id]], :include => :user)
    end
    @buttons = write_permission?
  end

  #Crear un nuevo programa de entrenamiento
  def new
    if request.get?
      @prog = Program.new
      @prog.private = log_owner.private_default
    else
      begin
        Program.transaction do
          #Crea el programa
          prog = Program.new(params[:prog])
          prog.user = current_user
          #prog.parent = nil
          #Aade al programa cada una de las sesiones
            params[:ses].sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |ses0|
              s = ses0[1]
              ps = ProgramSession.new
              ps.name = s[:name]
              ps.comments = s[:comments]
              ps.pos = s[:pos].to_i
              #Aade a cada sesion sus ejercicios
              s[:exercises].sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |ex0|
                ex = ex0[1]
                #Si el ejercicio es nuevo, se crea
                x = Exercise.find_or_create!(ex[:id], ex[:name], current_user)
                #Aadir los sets
                ex[:sets].sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |set0|
                  set= set0[1]
                  s = ProgramSet.new(set)
                  s.exercise = x
                  ps.program_sets << s
                end if ex[:sets] #This if prevents exception accessing a nil ex[:sets]
              end if s[:exercises] #This if prevents exception accessing a nil s[:exercises]
              prog.program_sessions << ps
            end if params[:ses] #This if prevents exception accessing a nil params[:ses]
          prog.save!
          prog.tag(params[:program_tags].downcase, {:separator => /[\s,;:]+/, :clear => true})
          @success = true
        end
      rescue
        log_error($!) if logger
        @success = false
      ensure
        render :partial => 'saving_result'
      end #begin
    end
  end

  #Editar un programa de entrenamiento
  def edit
    if request.get?
      @prog = load_whole_program
    else
      begin
        Program.transaction do
          prog = get_object
          #Cambia los atributos
          prog.update_attributes(params[:prog])
          prog.program_sessions.each do |x| x.destroy end
          #Aade al programa cada una de las sesiones
          params[:ses].sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |ses0|
            s = ses0[1]
            ps = ProgramSession.new
            ps.name = s[:name]
            ps.comments = s[:comments]
            ps.pos = s[:pos].to_i
            #Aade a cada sesion sus ejercicios
            s[:exercises].sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |ex0|
              ex = ex0[1]
              #Si el ejercicio es nuevo, se crea
              x = Exercise.find_or_create!(ex[:id], ex[:name], current_user)
              #Aadir los sets
              ex[:sets].sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |set0|
                set= set0[1]
                s = ProgramSet.new(set)
                s.exercise = x
                ps.program_sets << s
              end if ex[:sets] #This if prevents exception accessing a nil es[:sets]
            end if s[:exercises] #This if prevents exception accessing a nil s[:exercises]
            prog.program_sessions << ps
          end if params[:ses] #This if prevents exception accessing a nil params[:ses]
          prog.save!
          prog.tag(params[:program_tags].downcase, {:separator => /[\s,;:]+/, :clear => true})
          @success = true
        end
      rescue
        log_error($!) if logger
        @success = false
      ensure
        render :partial => 'saving_result'
      end #begin
    end
  end

  #Borrar una sesion de entrenamiento
  def delete
    if request.post?
      get_object.destroy
    end
    redirect_to(:action => "index")
  end

  #AJAX Crea el innerHTML de un <select> con las sesiones de un programa
  def program_sessions
    @program = current_user.programs.find(params[:id])
    render :partial => 'program_sessions'
  end

  #AJAX Devuelve una estructura con la informacin de la sesin de entrenamiento
  def program_session_sets
    #TODO: comprobar que el usuario tiene acceso a esta session
    @ses = ProgramSession.find(params[:id])
    render :partial => 'program_session_sets'
  end

  def copy
    if request.get?
      @program = get_object
      @program.private = log_owner.private_default
    else
      begin
        original = load_whole_program
        #Crea el programa
        prog = Program.new(params[:program])
        prog.user = current_user
        prog.parent = original
        prog.comments = original.comments
        #Aade al programa cada una de las sesiones
        original.program_sessions.each do |s|
          ps = ProgramSession.new
          ps.name = s.name
          ps.comments = s.comments
          ps.pos = s.pos
          #Aade a cada sesion sus ejercicios
          s.program_sets.each do |ex|
            #Si el ejercicio es nuevo, se crea
            x = Exercise.find_or_create!(1, ex.exercise.name, current_user)
            s = ProgramSet.new(ex.attributes)
            s.exercise = x
            ps.program_sets << s
          end
          prog.program_sessions << ps
        end
        prog.save!
        prog.tag(params[:tags])
        flash[:notice] = "Program copied."
      rescue
        log_error($!) if logger
        flash[:error] = "Error copying program."
      ensure
        #redirect_back_or_default({:action => :index})
        redirect_to :action => :index
      end #begin
    end
  end

  def pdf
    @program = load_whole_program
    @filename = @program.title.gsub(/[\s\/-]+/, '_').gsub(/[^0-9a-zA-Z_]/, '')
  end

  def csv
     #Program to export
    @program = load_whole_program

    #Filename
    filename = @program.title.gsub(/[\s\/-]+/, '_').gsub(/[^0-9a-zA-Z_]/, '')

    #Export
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
  end

private
  #fetch de la BD la session de entrenamiento pedida
  def get_object(*args)
    if args.size == 0
      @cached_program ||= log_owner.programs.find(params[:id])
    else
      log_owner.programs.find(params[:id], *args)
    end
  end

  def load_whole_program
     @whole_program ||= get_object(:include => [{:program_sessions => {:program_sets => :exercise}}])
  end

  #Si la session no es de este log, redirigir
  def valid_program
    begin
      #Lanza una excepcin si la sesion no existe o no pertenece al log
      #Tiene que llamarse @program, si no cascar la cach del show
      @program = get_object
      if @program.private && !write_permission?
        flash[:error] = 'Program does not exist or is private.'
        redirect_to :action => 'index'
      end
    rescue
      flash[:error] = 'Program does not exist.'
      redirect_to :controller => 'programs', :action => 'index'
    end
  end

  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter

  #Comprueba que la sesion de entrenamiento existe y est asociada con el log
  before_filter :valid_program, :only => [:show, :edit, :delete, :copy, :pdf, :csv]

  #Comprueba que el usuario actual es el dueo del log
  before_filter :write_permission_filter, :only => [:new, :edit, :delete]

  #Para copiar un programa hay que estar logueao
  before_filter :logged_in_filter, :only => [:copy]
end
