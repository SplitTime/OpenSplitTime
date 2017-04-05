module LinkHelper

  def reversed_sort_param(field, default = :asc)
    if default == :desc
      (params_indifferent_find(field) == :desc) ? "#{field}" : "-#{field}"
    else
      (params_indifferent_find(field) == :asc) ? "-#{field}" : "#{field}"
    end
  end

  def params_indifferent_find(field)
    params[:sort][field.to_s] || params[:sort][field.to_sym]
  end

  def toggled_sort_param(field_1, field_2)
    params[:sort].keys.map(&:to_s).include?(field_1.to_s) ? field_2.to_s : field_1.to_s
  end
end
