TimePoint = Struct.new(:lap, :split_id, :bitkey) do
  def sub_split
    split_id && bitkey && {split_id => bitkey}
  end
end