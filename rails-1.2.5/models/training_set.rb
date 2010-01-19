class TrainingSet < ActiveRecord::Base
	belongs_to :training_session
	belongs_to :exercise

	acts_as_list :scope => :training_session_id, :column => :pos

#	validates_length_of :ind, :maximum => 8
	validates_numericality_of :pos, :only_integer => true
	validates_numericality_of :sets, :only_integer => true
	validates_numericality_of :reps, :only_integer => true
	validates_numericality_of :weight
	validates_numericality_of :intensity
	validates_presence_of :pos, :sets, :reps, :weight
end
