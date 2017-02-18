class Hash

  # Convenience methods for parsing sub_splits

  def split_id
    keys.first
  end

  def bitkey
    values.first
  end

  # Methods to convert hash keys for export to JSON

  def camelize_keys
    update_keys(:camelize, :lower)
  end

  def underscore_keys
    update_keys(:underscore)
  end

  def update_keys(method, *args)
    self.keys.each do |key|
      updated_key = key.to_s.send(method, *args).to_sym
      self[updated_key] = self.delete(key)
      self[updated_key].update_keys(method, *args) if self[updated_key].kind_of? Hash
    end
    self
  end
end