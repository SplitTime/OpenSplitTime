# frozen_string_literal: true

TimePoint = Struct.new(:lap, :split_id, :bitkey) do
  include TimePointMethods

  def ==(other)
    return false unless other && [:lap, :split_id, :bitkey].all? { |method| other.respond_to?(method) }

    [lap, split_id, bitkey] == [other.lap, other.split_id, other.bitkey]
  end

  def lap_split_key
    lap && split_id && LapSplitKey.new(lap, split_id)
  end
end
