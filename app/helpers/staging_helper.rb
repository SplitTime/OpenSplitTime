module StagingHelper
  def staging_progress_bar(view_object)
    list_items = StagingForm.steps.map do |step|
      active = step == view_object.step ? 'active' : nil
      content_tag(:li, class: active) do
        content_tag(:p) { content_tag(:span, step.to_s.titleize) }
      end
    end

    content_tag :nav, class: 'progress-bar-nav' do
      content_tag :ul do
        list_items.sum
      end
    end
  end

  def staging_event_tabs(view_object)
    persisted_events = view_object.events.select(&:persisted?)
    persisted_list_items = persisted_events.map do |event|
      active = request.path == edit_event_path(event) ? 'active' : nil
      content_tag(:li, class: ['nav-item', active].compact.join(' ')) do
        link_to event.guaranteed_short_name, edit_event_path(event)
      end
    end

    new_item_active = (request.path == new_event_path(view_object.event_group) || persisted_events.empty?) ? 'active' : nil
    new_list_item = content_tag(:li, class: ['nav-item', new_item_active].compact.join(' ')) do
      link_to 'New Event', new_event_path(view_object.event_group)
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
        link_to course.name, courses_event_group_path(course_id: course.id)
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
      content_tag(:span, 'Continue', class: 'fa5-text-left') + fa_icon('arrow-right')
    end
  end

  def staging_previous_submit_button
    button_tag(type: :submit, value: 'Previous', class: 'btn btn-primary btn-large') do
      fa_icon 'arrow-left', text: 'Previous'
    end
  end

  def staging_save_submit_button
    button_tag(type: :submit, value: 'Save', class: 'btn btn-primary btn-large float-right') do
      fa_icon 'save', text: 'Save'
    end
  end

  def staging_previous_button(view_object)
    link_to(edit_event_path(view_object.first_course_event), class: 'btn btn-primary btn-large') do
      fa_icon 'arrow-left', text: 'Previous'
    end
  end

  def staging_continue_button(view_object)
    link_to(roster_event_group_path(view_object.event_group), class: 'btn btn-primary btn-large') do
      content_tag(:span, 'Continue', class: 'fa5-text-left') + fa_icon('arrow-right')
    end
  end
end
