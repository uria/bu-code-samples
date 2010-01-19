class UserProfile < ActiveRecord::Base
	belongs_to :user
	
	validates_inclusion_of :gender, :in => ['Male', 'Female'], :allow_nil => true

end
