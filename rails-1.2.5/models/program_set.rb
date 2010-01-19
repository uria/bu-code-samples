class ProgramSet < ActiveRecord::Base
	belongs_to :program_session
	belongs_to :exercise
	acts_as_list :scope => :program_session_id, :column => :pos

#	validates_length_of :ind, :maximum => 8
	validates_numericality_of :pos, :only_integer => true
	validates_numericality_of :sets, :only_integer => true
	validates_numericality_of :reps, :only_integer => true
	validates_numericality_of :intensity
	validates_presence_of :pos, :sets, :reps, :intensity
end
