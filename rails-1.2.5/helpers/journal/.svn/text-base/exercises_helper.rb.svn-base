module Journal::ExercisesHelper
def merge_error_messages(errors)
	unless errors.nil? || errors.empty?
		content_tag("div",
    	content_tag("h2","#{pluralize(errors.length, "error")} prohibited this exercises from being merged") +
    	content_tag("p", "There were problems with the following fields:") +
    	content_tag("ul", errors.collect { |msg| content_tag("li", msg)}),
    "id" => "errorExplanation", "class" => "errorExplanation")
  	end
	end
end
