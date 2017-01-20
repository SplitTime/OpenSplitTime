TimePoint = Struct.new(:lap, :split_id, :bitkey) do
  def sub_split
    split_id && bitkey && {split_id => bitkey}
  end

  def lap_split_id
    lap && split_id && LapSplitId.new(lap, split_id)
  end
end