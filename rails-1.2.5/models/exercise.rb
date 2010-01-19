class Exercise < ActiveRecord::Base
  has_many :training_sets
  has_many :program_sets
  belongs_to :user

  validates_length_of :name, :maximum => 64
  validates_presence_of :name

#  def self.find_or_create!(exercise_id, exercise_name, user)
#    #Si el usuario ya conoce el id del ejercicio
#    if exercise_id != -1
#      e = user.exercises.find(:first, :conditions => ["id = ? and name = ?", exercise_id, exercise_name])
#      return e unless e.nil?
#    end
#    e = Exercise.find(:first, :conditions => ["name = ?", exercise_name])
#    unless e.nil? #el ejercicio existe pero es la primera vez para el usuario
#      e.users.push(user)
#      return e
#    else  #el ejercicio es nuevo, nadie lo ha usado nunca
#      e = Exercise.create!({:name => exercise_name})
#      e.users.push(user)
#      return e
#    end
#  end

  def self.find_or_create!(exercise_id, exercise_name, user)
    #AHORA NO TIENE MUCHO SENTIDO, -1 LO PASABA COPY PROGRAM. UN EJERCICIO D ESOS
    #PUEDE SER NUEVO O NO, PERO NO LO SE POR EL ID ASI Q PASA SIEMPRE 1

    #Si el usuario ya conoce el id del ejercicio
    if exercise_id != -1
      e = user.exercises.find(:first, :conditions => ["name = ?", exercise_name])
    end
    #Si no se encontró o era nuevo (-1) directamente
    e = user.exercises.create({:name => exercise_name}) if e.nil?

    if e.nil?
      raise "Invalid exercise"
    else
      return e
    end
  end

end
