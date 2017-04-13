module LinkHelper

  def reversed_sort_param(field, default = :asc)
    if default == :desc
      prepared_params[:sort][field] == :desc ? "#{field}" : "-#{field}"
    else
      prepared_params[:sort][field] == :asc ? "-#{field}" : "#{field}"
    end
  end

  def toggled_sort_param(field_1, field_2)
    prepared_params[:sort].has_key?(field_1) ? field_2 : field_1
  end
end
