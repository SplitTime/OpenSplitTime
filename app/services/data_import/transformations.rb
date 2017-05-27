module DataImport::Transformations
  def map_keys!(model_name)
    parsed_data.each do |struct|
      params_class(model_name).mapping.each do |old_key, new_key|
        struct[new_key] = struct.delete_field(old_key) if struct.respond_to?(old_key)
      end
    end
  end

  def normalize_gender!
    parsed_data.each do |struct|
      if struct.gender.present?
        struct.gender = struct.gender.downcase.start_with?('m') ? 'male' : 'female'
      end
    end
  end

  def params_class(model_name)
    "#{model_name.to_s.classify}Parameters".constantize
  end

  def split_full_name!
    parsed_data.each do |struct|
      full_name = struct.delete_field(:full_name)
      names = full_name.to_s.split
      first = names.size < 2 ? names.first : names[0..-2].join(' ')
      last = names.size < 2 ? nil : names.last
      struct.first_name, struct.last_name = first, last
    end
  end
end
