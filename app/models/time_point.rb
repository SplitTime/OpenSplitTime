# frozen_string_literal: true

TimePoint = Struct.new(:lap, :split_id, :bitkey) do
  include TimePointMethods

  def ==(other)
    return false unless other && [:lap, :split_id, :bitkey].all? { |method| other.respond_to?(method) }
    [self.lap, self.split_id, self.bitkey] == [other.lap, other.split_id, other.bitkey]
  end

  def lap_split_key
    lap && split_id && LapSplitKey.new(lap, split_id)
  end

  def complete?
    lap && split_id && bitkey
  end
end
