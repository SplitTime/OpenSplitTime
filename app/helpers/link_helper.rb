module LinkHelper

  def reversed_sort_param(field, default = :asc)
    if default == :desc
      (params[:sort][field] == :desc) ? "#{field}" : "-#{field}"
    else
      (params[:sort][field] == :asc) ? "-#{field}" : "#{field}"
    end
  end

  def toggled_sort_param(field_1, field_2)
    params[:sort].keys.include?(field_1.to_s) ? field_2.to_s : field_1.to_s
  end
end
