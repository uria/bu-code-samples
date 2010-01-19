module Journal::ProgramsHelper

	def program_to_javascript(program)
		str = 'sessions_exercises = [' + program.program_sessions.collect {|ses| program_session_to_javascript(ses)}.join(',') +'];'
		str += 'sessions_name = [' + program.program_sessions.collect {|ses| '"' + escape_javascript(ses.name) + '"'}.join(',')+'];'
		str += 'sessions_comments = [' + program.program_sessions.collect {|ses| '"' + escape_javascript(ses.comments) + '"'}.join(',') + '];'
	end

	def program_session_to_javascript(session)
		exercises = partitionize(session.program_sets)
		'[' + exercises.collect { |x| sprintf('["%s",%d,[%s]]',escape_javascript(x[0].exercise.name), x[0].exercise.id,
								x.collect{|y| sprintf('[%d, %d, %.3g]',y.sets,y.reps,y.intensity)}.join(','))}.join(',') + ']'
	end
end
