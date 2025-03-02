module ApplicationHelper
  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
    when :success, :notice
      "bg-secondary"
    when :error, :alert
      "bg-danger"
    when :warning
      "bg-warning"
    when :info
      "bg-secondary"
    else
      "bg-secondary"
    end
  end
end
