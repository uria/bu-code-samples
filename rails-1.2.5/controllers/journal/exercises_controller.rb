class Journal::ExercisesController < ApplicationController
  layout 'log'

  #Lista mis ejercicios
  def my_exercises
    @exercises = log_owner.exercises
   
    render :partial => 'my_exercises'
  end

#  def index
#    if params[:tagged]
#      @pages, @exercises = paginate_tagged('Exercise', params[:tagged], :per_page =>15,
#    						        	:conditions => "user_id = #{log_owner.id}",
#  	     								:order => 'name ASC')
#  		
#    else  	#Listar todos los ejercicios (paginar)
#      @pages, @exercises = paginate(:exercises,  :per_page =>15,
#  	  								    :conditions => ["user_id = ?", log_owner.id],
#  	  								    :order => 'name ASC')
#    end
#
#		@buttons = write_permission?
#  end
#  
#  def show
#  	@exercise = get_exercise
#		@buttons = write_permission?
#  end
#  
#  def edit
#    if request.get?
#      @exercise = get_exercise
#  	else
#      @exercise = get_exercise
#      if @exercise.update_attributes(params[:exercise])
#		@exercise.tag(params[:tags], :clear => true)
#	  	redirect_to :action => :index
#	  else
#	   flash.now
#      end
#  	end
#  end
#  
#  def merge
#  	if request.get?
#  		@exercise_to_preserve = Exercise.new
#  		@exercise_to_rename = Exercise.new
#  	else
#  		@errors = Array.new
#  		unless @exercise_to_preserve = log_owner.exercises.find(:first, :conditions => ["name = ?", params[:exercise_to_preserve][:name]])
#  			@exercise_to_preserve = Exercise.new(params[:exercise_to_preserve]) 
#  			@errors << "Exercise to preserve does no exist."
#  		end
#  		unless @exercise_to_rename = log_owner.exercises.find(:first, :conditions => ["name = ?", params[:exercise_to_rename][:name]])
#			@exercise_to_rename = Exercise.new(params[:exercise_to_rename]) 
#  			@errors << "Exercise to rename does no exist."			
#  		end
#  		if @errors.empty?
#  			TrainingSet.update_all("exercise_id=#{@exercise_to_preserve.id}", "exercise_id=#{@exercise_to_rename.id}")
#  			ProgramSet.update_all("exercise_id=#{@exercise_to_preserve.id}", "exercise_id=#{@exercise_to_rename.id}")
#  			@exercise_to_rename.destroy
#  			redirect_to :action => :index
#  		end
#  	end
#  end
  
private
	
#	#Devuelve el ejercicio cuyo id se ha pasado como parametro
#	def get_exercise
#			@exercise ||= log_owner.exercises.find(params[:id])
#	end	
#
#	#Comprueba que el ejercicio existe y pertenece al log
#	def valid_exercise_filter
#		begin		
#			#Lanza una excepción si la sesion no existe
#			get_exercise	
#		rescue
#			flash[:notice] = 'Invalid exercise.'
#			redirect_to :action => 'index'  	
#		end		
#	end 
  
  #Comprueba que se accede a un log que existe
  before_filter :valid_log_filter
  
#  #Comprueba que la sesion de entrenamiento existe y está asociada con el log
#  before_filter :valid_exercise_filter, :only => [:show, :edit]
#  
#  #Comprueba que el usuario actual es el dueño del log
#  before_filter :write_permission_filter, :only => [:edit, :merge]
	
	before_filter :write_permission_filter, :only => [:my_exercises]
  
end
