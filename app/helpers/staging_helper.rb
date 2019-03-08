module StagingHelper
  def staging_progress_bar(view_object)
    step_items = [
        {step: :your_event,
         link: edit_event_group_path(view_object.event_group)},
        {step: :event_details,
         link: view_object.events.present? ?
                   edit_event_path(view_object.events.first) :
                   new_event_path(view_object.event_group)},
        {step: :courses,
         link: edit_course_path(view_object.events.first&.course)},
        {step: :entrants,
         link: roster_event_group_path(view_object.event_group)},
        {step: :confirmation, link: '#'},
        {step: :published, link: '#'}
    ]

    list_items = step_items.map do |item|
      active = item[:step] == view_object.step ? 'active' : nil
      content_tag(:li, class: active) { link_to(item[:link]) { content_tag(:span, item[:step].to_s.titleize) } }
    end

    content_tag :nav, class: "progress-bar-nav" do
      content_tag :ul do
        list_items.sum
      end
    end
  end
end
