class Hash

  # Convenience methods for parsing sub_splits

  def split_id
    keys.first
  end

  def bitkey
    values.first
  end
end