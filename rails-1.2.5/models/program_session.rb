class ProgramSession < ActiveRecord::Base
	belongs_to :program
	has_many :program_sets, :dependent => :delete_all, :order => 'pos ASC'	
	
	validates_length_of :name, :maximum => 64
	validates_numericality_of :pos, :only_integer => true
	validates_presence_of :name, :pos
end
