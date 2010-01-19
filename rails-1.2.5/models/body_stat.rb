class BodyStat < ActiveRecord::Base
	belongs_to :user

	validates_numericality_of :bodyweight
	validates_numericality_of :bodyfat, :allow_nil => true
	#validates_format_of :bodyfat, :with => /^\s*\d+(\.\d+)?\s*%?\s*$/
	validates_presence_of :measured_on

	attr_protected :user_id

protected
	def validate
		errors.add(:bodyweight, "should be positive") if !bodyweight.nil? && bodyweight <= 0.0
		errors.add(:bodyfat, "should be a number between 0 and 100") unless bodyfat==nil || (bodyfat >= 0.0 && bodyfat <= 100.0)
	end

	class << self # Class methods
		public
			def historic(user, from, to)
				connection.select_all("select measured_on as t, bodyweight, bodyfat from body_stats where user_id=%s and measured_on>='%s' and measured_on<='%s' order by measured_on ASC" % [user.id, from, to].collect{ |value| connection.quote_string(value.to_s)})
			end
	end
end
