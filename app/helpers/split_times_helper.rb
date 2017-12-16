module SplitTimesHelper

  STATUS_INDICATORS = {bad: %w([* *]), questionable: %w([ ])}.with_indifferent_access

  def composite_time(row)
    time_array = row.times_from_start.zip(row.time_data_statuses).map do |time, status|
      brackets = STATUS_INDICATORS.fetch(status, ['', ''])
      time ? "#{brackets.first}#{time_format_xxhyym(time)}#{brackets.last}" : '--:--:--'
    end

    time_array.join(' / ')
  end

  def composite_time_zzs(row)
    time_array = row.times_from_start.zip(row.time_data_statuses).map do |time, status|
      brackets = STATUS_INDICATORS.fetch(status, ['', ''])
      time ? "#{brackets.first}#{time_format_xxhyymzzs(time)}#{brackets.last}" : '--:--:--'
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
