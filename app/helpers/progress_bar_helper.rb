# frozen_string_literal: true

module ProgressBarHelper
  def bootstrap_progress_bar(min_value:, max_value:, current_value:)
    percent_complete = (current_value.to_f / max_value) * 100

    content_tag(
      :div, nil,
      {class: "progress-bar",
      role: "progressbar",
      style: "width: #{percent_complete}%",
      "aria-valuenow" => current_value,
      "aria-valuemin" => min_value,
      "aria-valuemax" => max_value,}
    )
  end
end
