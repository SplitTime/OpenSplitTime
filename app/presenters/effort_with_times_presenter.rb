# frozen_string_literal: true

class EffortWithTimesPresenter < EffortWithLapSplitRows

  delegate :id, :split_times, :event, :event_name, :full_name, :bib_number, :finish_status, :to_param, to: :effort

  def post_initialize(args)
    ArgsValidator.validate(params: args, required: [:effort, :params], exclusive: [:effort, :params], class: self.class)
    @effort = args[:effort]
    @params = args[:params] || {}
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
