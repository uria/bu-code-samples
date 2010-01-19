module Journal::LogHelper

	def training_session_to_javascript(session)
		exercises = partitionize(session.training_sets)
	  '[' + exercises.collect { |x| sprintf('["%s",%d,[%s]]',escape_javascript(x[0].exercise.name), x[0].exercise.id, x.collect{|y| sprintf('[%d, %d, %s, %.3g]',y.sets,y.reps,weight_without_units(y.weight),y.intensity)}.join(','))}.join(',') +'];'
	end

end
