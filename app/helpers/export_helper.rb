module ExportHelper
  def button_to_course_group_best_efforts_export_async(view_object)
    path = export_async_organization_course_group_best_efforts_path(
      view_object.organization,
      view_object.course_group,
      filter: view_object.request[:filter]
    )

    button_to(path, method: :post, class: "btn btn-md btn-success") do
      fa_icon("file-csv", text: "Export CSV")
    end
  end

  def button_to_course_group_finishers_export_async(view_object)
    path = export_async_organization_course_group_finishers_path(
      view_object.organization,
      view_object.course_group,
      filter: view_object.request[:filter],
      sort: view_object.request[:sort]
    )

    button_to(path, method: :post, class: "btn btn-md btn-success") do
      fa_icon("file-csv", text: "Export CSV")
    end
  end
end
