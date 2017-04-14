module LinkHelper

  def reversed_sort_param(presenter, field, default = :asc)
    if default == :desc
      presenter.sort_hash[field] == :desc ? "#{field}" : "-#{field}"
    else
      presenter.sort_hash[field] == :asc ? "-#{field}" : "#{field}"
    end
  end

  def toggled_sort_param(presenter, field_1, field_2)
    presenter.sort_hash.has_key?(field_1) ? field_2 : field_1
  end
end
