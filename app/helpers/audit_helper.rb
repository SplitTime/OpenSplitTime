module AuditHelper
  def link_to_rebuild_times(view_object)
    link_to 'Rebuild Times', rebuild_effort_path(view_object.effort),
            method: :patch,
            data: {confirm: "This will delete all split times and attempt to rebuild them from the " +
              "#{pluralize(view_object.raw_times_count, 'raw time')} related to this effort. This action cannot be undone. Proceed?"},
            class: 'btn btn-sm btn-warning'
  end
end