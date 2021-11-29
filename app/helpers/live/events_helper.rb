# frozen_string_literal: true

module Live::EventsHelper
  def display_progress_info(args)
    split_name = args[:split_name]
    absolute_times_local = args[:absolute_times_local]

    split_name ? "#{split_name} at #{join_absolute_times(absolute_times_local)}" : '[not recorded]'
  end

  def display_progress_lap_and_times(args)
    lap_name = args[:lap_name]
    absolute_times_local = args[:absolute_times_local]

    [lap_name.presence, join_absolute_times(absolute_times_local)].compact.join(': ')
  end

  def display_progress_times_only(args)
    join_absolute_times(args[:absolute_times_local])
  end

  def display_progress_in_time_only(args)
    join_absolute_times(args[:absolute_times_local].first(1))
  end

  def join_absolute_times(absolute_times_local)
    absolute_times_local.present? ?
        absolute_times_local.map(&method(:day_time_military_format)).join(' / ') : '[not recorded]'
  end
end
