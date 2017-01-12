TimePoint = Struct.new(:split_id, :bitkey, :lap) do
  def sub_split
    split_id && bitkey && {split_id => bitkey}
  end
end