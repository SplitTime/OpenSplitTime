# frozen_string_literal: true

module SplitsHelper
  def link_to_split_edit(split)
    url = edit_split_path(split)
    tooltip = "Edit this split"
    options = { data: { controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-primary" }
    link_to fa_icon("pencil-alt"), url, options
  end

  def set_course_and_event
    if params[:event_id]
      @event = Event.friendly.find(params[:event_id])
      @course = @event.course
    else
      @event = nil
      @course = Course.friendly.find(params[:course_id]) if params[:course_id]
    end
  end
end
