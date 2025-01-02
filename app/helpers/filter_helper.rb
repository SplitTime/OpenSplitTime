module FilterHelper
  def filter_count_text(filtered_count, total_count, resource_name)
    resource_type_with_count = pluralize(total_count, resource_name)

    if filtered_count == total_count
      "Showing #{resource_type_with_count}"
    else
      "Showing #{filtered_count} of #{resource_type_with_count}"
    end
  end
end
