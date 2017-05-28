module DataImport::Transformable

  def map_keys!(map)
    map.each do |old_key, new_key|
      attributes[new_key] = attributes.delete_field(old_key) if attributes.respond_to?(old_key)
    end
  end

  def merge_attributes!(merging_attributes)
    merging_attributes.each { |key, value| attributes[key] = value }
  end

  def normalize_gender!
    gender = attributes.gender
    if gender.present?
      attributes.gender = gender.downcase.start_with?('m') ? 'male' : 'female'
    end
  end

  def params_class(model_name)
    "#{model_name.to_s.classify}Parameters".constantize
  end

  def split_field!(old_field, first_field, second_field, split_char = ' ')
    old_value = attributes.delete_field(old_field)
    values = old_value.to_s.split(split_char)
    first_value = values.size < 2 ? values.first : values[0..-2].join(split_char)
    second_value = values.size < 2 ? nil : values.last
    attributes[first_field], attributes[second_field] = first_value, second_value
  end

  def permit!(permitted_params)
    attributes.to_h.keys.each do |key|
      attributes.delete_field(key) unless permitted_params.include?(key)
    end
  end
end
