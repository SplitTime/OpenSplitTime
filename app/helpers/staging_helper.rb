module StagingHelper
  def staging_progress_bar(view_object)
    your_event_link = view_object.event_group.persisted? ? edit_event_group_path(view_object.event_group) : new_event_group_path
    event_details_link = view_object.step_enabled?(:event_details) ? edit_event_group_path(view_object.event_group) : '#'
    courses_link = view_object.step_enabled?(:courses) ? edit_course_path(view_object.events.first&.course) : '#'
    entrants_link = view_object.step_enabled?(:entrants) ? roster_event_group_path(view_object.event_group) : '#'

    step_items = [
        {step: :your_event,
         link: your_event_link},
        {step: :event_details,
         link: event_details_link},
        {step: :courses,
         link: courses_link},
        {step: :entrants,
         link: entrants_link},
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
