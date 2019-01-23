# frozen_string_literal: true

class EffortWithTimesPresenter < EffortWithLapSplitRows
  def post_initialize(effort, args)
    ArgsValidator.validate(subject: effort, params: args, required: [:params], exclusive: [:params], class: self.class)
    @effort = effort
    @params = args[:params] || {}
  end

  def autofocus_for_time_point?(time_point)
    military_times? ? time_point == time_points.first : time_point == time_points.second
  end

  def disable_for_time_point?(time_point)
    return false if military_times?
    time_point == time_points.first
  end

  def display_style
    params[:display_style]
  end

  def guaranteed_split_time(time_point)
    split_times.find { |st| st.time_point == time_point } || SplitTime.new(time_point: time_point, effort_id: id)
  end

  def table_header
    military_times? ? 'Times of Day' : 'Elapsed Times'
  end

  def working_field
    military_times? ? :military_time : :elapsed_time
  end

  private

  attr_reader :params

  def military_times?
    params[:display_style] == 'military_times'
  end
end
