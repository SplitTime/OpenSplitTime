# Based on TimeDifference gem v 0.5.0

class TimeDifference

  private_class_method :new

  TIME_COMPONENTS = [:years, :months, :weeks, :days, :hours, :minutes, :seconds]

  def self.between(start_time, end_time)
    new(start_time, end_time, absolute: true)
  end

  def self.from(start_time, end_time)
    new(start_time, end_time, absolute: false)
  end

  def in_years
    in_component(:years)
  end

  def in_months
    (time_diff / (1.day * 30.42)).round(2)
  end

  def in_weeks
    in_component(:weeks)
  end

  def in_days
    in_component(:days)
  end

  def in_hours
    in_component(:hours)
  end

  def in_minutes
    in_component(:minutes)
  end

  def in_seconds
    time_diff
  end

  def in_milliseconds
    (time_diff * 1000).to_i
  end
  alias_method :in_ms, :in_milliseconds

  private

  def initialize(start_time, end_time, absolute:)
    start_time = time_in_seconds(start_time)
    end_time = time_in_seconds(end_time)

    @time_diff = absolute ? (end_time - start_time).abs : end_time - start_time
  end

  attr_reader :time_diff

  def time_in_seconds(time)
    time.to_time.to_f
  end

  def in_component(component)
    (time_diff / 1.send(component)).round(2)
  end

end