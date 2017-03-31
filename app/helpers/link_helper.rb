module LinkHelper

  def reversed_sort_param(field)
    (params[:sort][field.to_sym] == :desc) ? "#{field}" : "-#{field}"
  end

  def toggled_sort_param(field_1, field_2)
    params[:sort].keys.include?(field_1.to_sym) ? field_2.to_s : field_1.to_s
  end
end
