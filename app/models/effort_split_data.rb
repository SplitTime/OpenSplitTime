# frozen_string_literal: true

class EffortSplitData
  attr_reader :effort_slug, :lap_name, :split_name, :absolute_times_local

  def initialize(args)
    @effort_slug = args[:effort_slug]
    @lap_name = args[:lap_name]
    @split_name = args[:split_name]
    @absolute_times_local = args[:absolute_times_local]
  end

  def <=>(other)
    (absolute_times_local.compact.first&.to_i || 0) <=> (other.absolute_times_local.compact.first&.to_i || 0)
  end

  def [](arg)
    send(arg)
  end
end
