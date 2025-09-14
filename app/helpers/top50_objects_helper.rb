module Top50ObjectsHelper
  def get_status_classname(obj)
    valid = obj.is_valid
    if valid == 0
      return "non_valid"
    elsif valid == 1
      return "valid"
    elsif valid == 2
      return "new"
    else
      return "error"
    end
  end
end
