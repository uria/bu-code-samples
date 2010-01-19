module AdminHelper
  def humanize_kind(k)
    case k
      when 1
        "Beta"
      when 2
        "Trial"
      when 3
        "Paying"
      else
        "Unknown Kind!!"
    end
  end

end
