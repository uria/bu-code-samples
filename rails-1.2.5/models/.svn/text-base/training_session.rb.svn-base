class TrainingSession < ActiveRecord::Base
  belongs_to :user
  belongs_to :program
  has_many :training_sets, :dependent => :delete_all, :order => 'pos ASC'
  has_many :users_comments, :class_name => 'Comment', :as => :commentable, :order => 'comments.created_at ASC', :dependent => :delete_all
  has_many :highlighted_workouts, :dependent => :delete_all

  validates_length_of :title, :maximum => 64

   # Crea sets y los asigna a la sesion de entrenamiento sin salvarlos.
  #Recibe dos parametros, el primero es un hash de la forma:
  #{"0" => {"0" => {"exercise_id" => "1", "exercise" => "bench press", "sets" => "3", "reps" => "8", "weight" => "100"},
  #          "1" => {"sets" => "3", "reps" => "8", "weight" => "100", "intensity" => "0.75"}},
  #  "1" => {"0" => {"exercise_id" => "-1", "exercise" => "new exercise", "sets" => "3", "reps" => "8", "weight" => "100"},
  #          "1" => {"sets" => "3", "reps" => "8", "weight" => "100", , "intensity" => "0.75"}}}

  # En caso de que un ejercicio tenga id=-1 se crear el ejercicio dandole como dueño el usuario con id pasado como segundo parametro
  # esos ejercicios sí que se salvan a la BD y se levanta excepción en caso de error
  def build_training_sets_from_hash!(set, user)
    sets_to_create = []
    #Para cada uno de los sets
    set.sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |x0|
      x = x0[1]
      #Asegurarse de que el ejercicio pertenece al usuario o crearlo si es nuevo
      if(x['0']['exercise_id'] == "-1") #Si es nuevo
        ne = Exercise.find_or_create!(-1,x['0']['exercise'],user)
        x['0']['exercise_id'] = ne.id
      else
        #Esto quizás debería estar en el modelo de trainingset, aquí lo hacemos una vez por ejercicio nada mas
        user.owns_exercise! x['0']['exercise_id']
      end

      #Para poder salvarlo debemos quitarle exercise para que no piense que es un atributo
      x['0'].delete('exercise')

      #Para cada uno de los sets del mismo ejercicio
      x.sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |y0|
          y = y0[1]
          y['exercise_id'] = x['0']['exercise_id']
          training_sets.build(y)
      end
    end
  end

  def volume
     training_sets.inject(0) {|sum, set| sum + set.sets * set.reps * set.weight}
  end

  def number_of_lifts
    training_sets.inject(0) {|sum, set| sum + set.sets * set.reps}
  end

  def  avg_intensity
    training_sets.inject(0) {|sum, set| sum + set.sets * set.reps * set.intensity} / number_of_lifts
  end

  def max_intensity
    training_sets.inject(0) {|max, set| set.intensity > max ? set.intensity : max }
  end

  class << self
  public
    def historic(user, from, to)
      connection.select_all("select done_on as t, sum(sets*reps) as NOL, sum(sets*reps*weight) as volume , max(intensity) as max_int, avg(intensity) as avg_int from training_sessions inner join training_sets where training_sets.training_session_id = training_sessions.id and user_id=%s and training_sessions.done_on>='%s' and training_sessions.done_on<='%s' group by done_on order by done_on asc" % [user.id, from, to].collect { |value| connection.quote_string(value.to_s)})
    end

    def intensityStack(user, from, to)
      connection.select_all("SELECT floor(intensity*10+0.0001)*10 AS intensity, sum(reps*sets) AS NOL, sum(reps*sets*weight) AS volume, done_on as t FROM training_sets INNER JOIN training_sessions ON training_session_id = training_sessions.id WHERE user_id=%s and training_sessions.done_on>='%s' and training_sessions.done_on<='%s' GROUP BY done_on, intensity ORDER BY intensity DESC, done_on ASC" % [user.id, from, to].collect { |value| connection.quote_string(value.to_s)})
    end
  end
end
