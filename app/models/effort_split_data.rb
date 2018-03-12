# frozen_string_literal: true

class EffortSplitData
  attr_reader :effort_slug, :lap_name, :split_name, :days_and_times

  def initialize(args)
    @effort_slug = args[:effort_slug]
    @lap_name = args[:lap_name]
    @split_name = args[:split_name]
    @days_and_times = args[:days_and_times]
  end

  def <=>(other)
    (days_and_times.compact.first&.to_i || 0) <=> (other.days_and_times.compact.first&.to_i || 0)
  end

  def [](arg)
    send(arg)
  end
end
