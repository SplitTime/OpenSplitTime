# frozen_string_literal: true

module ExportHelper
  def link_to_course_group_best_efforts_export_async(view_object)
    link_to fa_icon("file-csv", text: "Export CSV"),
            export_async_organization_course_group_best_efforts_path(view_object.organization, view_object.course_group, filter: view_object.request[:filter]),
            method: :post,
            class: "btn btn-md btn-success"
  end
end
