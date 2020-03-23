OrderedEffortsAtTimePoint = Struct.new(:lap, :split_id, :sub_split_bitkey, :effort_ids, keyword_init: true) do
  def effort_id_array
    effort_ids.gsub(/[^\d,]/, "").split(",").map(&:to_i)
  end
end
