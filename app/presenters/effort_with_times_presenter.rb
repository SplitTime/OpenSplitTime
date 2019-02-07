# frozen_string_literal: true

class EffortWithTimesPresenter < EffortWithLapSplitRows
  def post_initialize(effort, args)
    ArgsValidator.validate(subject: effort, params: args, required: [:params], exclusive: [:params], class: self.class)
    @effort = effort
    @params = args[:params] || {}
  end

  def autofocus_for_time_point?(time_point)
    time_point == first_enabled_time_point
  end

  def disable_for_time_point?(time_point)
    return false unless elapsed_times?
    time_point == time_points.first
  end

  def display_style
    params[:display_style].presence || default_display_style
  end

  def guaranteed_split_time(time_point)
    split_times.find { |st| st.time_point == time_point } || SplitTime.new(time_point: time_point, effort_id: effort.id)
  end

  def html_value(time_point)
    date_included? ? datetime_html_value(time_point) : field_value(time_point)
  end

  def placeholder
    date_included? ? 'mm/dd/yyyy hh:mm:ss' : 'hh:mm:ss'
  end

  def subtext
    elapsed_times? ?
        "All times are elapsed since #{I18n.localize(actual_start_time_local, format: :full_day_military_and_zone)}" :
        "All times are in #{home_time_zone}"
  end

  def table_header
    display_style.sub('time', 'times').titleize
  end

  def working_field
    display_style.to_sym
  end

  private

  attr_reader :params

  def default_display_style
    'military_time'
  end

  def datetime_html_value(time_point)
    field_value = field_value(time_point)
    return nil unless field_value
    I18n.localize(field_value, format: :datetime_input)
  end

  def field_value(time_point)
    guaranteed_split_time(time_point).send(working_field)
  end

  def first_enabled_time_point
    @first_enabled_time_point ||= time_points.find { |tp| !disable_for_time_point?(tp) }
  end

  def elapsed_times?
    working_field.in?([:elapsed_time])
  end

  def date_included?
    working_field.in?([:absolute_time_local])
  end
end
