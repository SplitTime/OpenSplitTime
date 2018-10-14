module BitkeyDefinitions
  def in_bitkey
    SubSplit::IN_BITKEY
  end

  def out_bitkey
    SubSplit::OUT_BITKEY
  end

  def in_only_bitmap
    in_bitkey
  end

  def in_out_bitmap
    in_bitkey | out_bitkey
  end
end
