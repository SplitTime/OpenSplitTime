class Hash

  # Convenience methods for parsing bitkey_hashes

  def split_id
    keys.first
  end

  def bitkey
    values.first
  end
end