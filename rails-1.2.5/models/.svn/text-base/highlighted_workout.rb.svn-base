class HighlightedWorkout < ActiveRecord::Base
  belongs_to :training_session

  #Valida que existe una sesion de entrenamiento asociada
  validates_presence_of :training_session, :message => "invalid"
  #validates_associated :training_session

end
