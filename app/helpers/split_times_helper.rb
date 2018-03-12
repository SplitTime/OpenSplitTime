# frozen_string_literal: true

module SplitTimesHelper

  STATUS_INDICATORS = {bad: %w([* *]), questionable: %w([ ])}.with_indifferent_access

  def composite_time(row, options = {})
    with_seconds = options[:with_seconds]
    time_array = row.times_from_start.zip(row.time_data_statuses, row.stopped_here_flags).map do |time, status, stopped|
      brackets = STATUS_INDICATORS.fetch(status, ['', ''])
      stop_indicator = (stopped && !row.finish?) ? ' [DONE]' : ''
      time_string = with_seconds ? time_format_hhmmss(time) : time_format_hhmm(time)
      time_string ? "#{brackets.first}#{time_string}#{brackets.last}#{stop_indicator}" : '--:--:--'
    end

    time_array.join(' / ')
  end

  def combined_days_times(row)
    row.days_and_times.map { |time| day_time_format(time) }.join(' / ')
  end

  def combined_days_times_military(row)
    row.days_and_times.map { |time| day_time_military_format(time) }.join(' / ')
  end

  def combined_pacer(row)
    row.pacer_in_out.compact.map { |boolean| humanize_boolean(boolean) }.join(' / ')
  end
end
