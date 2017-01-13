LapSplit = Struct.new(:lap, :split) do
  def name
    lap && split && "#{split.base_name} Lap #{lap}"
  end

  def time_point
    lap && split && TimePoint.new(lap, split.id)
  end
end