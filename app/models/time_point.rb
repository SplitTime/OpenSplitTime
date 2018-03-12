# frozen_string_literal: true

TimePoint = Struct.new(:lap, :split_id, :bitkey) do
  def sub_split
    split_id && bitkey && {split_id => bitkey}
  end

  def lap_split_key
    lap && split_id && LapSplitKey.new(lap, split_id)
  end

  def kind
    bitkey && SubSplit.kind(bitkey)
  end

  def in?
    kind == 'In'
  end

  def out?
    kind == 'Out'
  end
end