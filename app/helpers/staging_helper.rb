module StagingHelper
  def staging_progress_bar(view_object)
    list_items = StageEventGroupsController::STEPS.map do |step|
      active = step == view_object.current_step ? 'active' : nil
      content_tag(:li, class: active) do
        content_tag(:p) { content_tag(:span, step.titleize) }
      end
    end

    content_tag :nav, class: 'progress-bar-nav' do
      content_tag :ul do
        list_items.sum
      end
    end
  end

  def staging_event_tabs(view_object)
    persisted_events = view_object.ordered_events.select(&:persisted?)
    persisted_list_items = persisted_events.map do |event|
      path_for_event = edit_stage_event_group_path(view_object.event_group, step: :event_details, event: {id: event.id})
      active = view_object.event.id == event.id ? 'active' : nil
      content_tag(:li, class: ['nav-item', active].compact.join(' ')) do
        link_to event.guaranteed_short_name, path_for_event
      end
    end

    path_for_new_event = edit_stage_event_group_path(view_object.event_group, step: :event_details, event: {id: nil})
    new_item_active = view_object.event.new_record? ? 'active' : nil
    new_item_label = new_item_active ? 'New Event' : fa_icon('plus')
    new_list_item = content_tag(:li, class: ['nav-item', new_item_active].compact.join(' ')) do
      link_to new_item_label, path_for_new_event
    end

    content_tag(:ul, class: 'nav nav-tabs nav-tabs-ost') do
      (persisted_list_items + [new_list_item]).sum
    end
  end

  def staging_course_tabs(view_object)
    courses = view_object.courses
    list_items = courses.map do |course|
      active = view_object.course == course ? 'active' : nil
      content_tag(:li, class: ['nav-item', active].compact.join(' ')) do
        link_to course.name, edit_stage_event_group_path(view_object.event_group, step: :courses, course: {id: course.id})
      end
    end

    content_tag(:ul, class: 'nav nav-tabs nav-tabs-ost') do
      list_items.sum
    end
  end

  # Hitting Return/Enter from a text field submits the form using the first submit button
  # found within the form, so use a hidden button to make "Continue" the default
  def staging_hidden_continue_button
    button_tag('', type: :submit, value: 'Continue', class: 'default-button-handler', tabindex: '-1')
  end

  def staging_continue_submit_button
    button_tag(type: :submit, value: 'Continue', class: 'btn btn-primary btn-large') do
      fa_icon 'arrow-right', text: 'Continue', right: true
    end
  end

  def staging_previous_submit_button
    button_tag(type: :submit, value: 'Previous', class: 'btn btn-outline-secondary btn-large') do
      fa_icon 'arrow-left', text: 'Previous'
    end
  end

  def staging_save_submit_button
    button_tag(type: :submit, value: 'Save', class: 'btn btn-primary btn-large float-right') do
      fa_icon 'save', text: 'Save'
    end
  end
end
