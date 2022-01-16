# frozen_string_literal: true

module ProgressMonitorablesHelper
  def progress_monitorable_status_component(progress_monitorable)
    return unless progress_monitorable.status?

    status_colors = {
      waiting: "black",
      extracting: "pink",
      transforming: "yellow",
      loading: "cyan",
      processing: "blue",
      finished: "green",
      failed: "red"
    }.with_indifferent_access

    content_tag(:div) do
      label = " #{progress_monitorable.status.titleize}"
      icon = fa_icon("circle", style: "color:#{status_colors[progress_monitorable.status]}")
      icon + label
    end
  end
end
