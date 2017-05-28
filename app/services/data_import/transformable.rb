module DataImport::Transformable

  def map_keys!(map)
    map.each do |old_key, new_key|
      self[new_key] = delete_field(old_key) if attributes.respond_to?(old_key)
    end
  end

  def merge_attributes!(merging_attributes)
    merging_attributes.each { |key, value| self[key] = value }
  end

  def normalize_gender!
    gender = self[:gender]
    if gender.present?
      self[:gender] = gender.downcase.start_with?('m') ? 'male' : 'female'
    end
  end

  def params_class(model_name)
    "#{model_name.to_s.classify}Parameters".constantize
  end

  def split_field!(old_field, first_field, second_field, split_char = ' ')
    old_value = delete_field(old_field)
    values = old_value.to_s.split(split_char)
    first_value = values.size < 2 ? values.first : values[0..-2].join(split_char)
    second_value = values.size < 2 ? nil : values.last
    self[first_field], self[second_field] = first_value, second_value
  end

  def permit!(permitted_params)
    to_h.keys.each do |key|
      delete_field(key) unless permitted_params.include?(key)
    end
  end
end
