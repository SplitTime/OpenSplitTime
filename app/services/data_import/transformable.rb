module DataImport::Transformable

  def align_split_distance!(split_distances)
    return unless self[:distance_from_start].present?
    match_threshold = 10
    matching_distance = split_distances.find do |distance|
      (distance - self[:distance_from_start]).abs < match_threshold
    end
    self[:distance_from_start] = matching_distance if matching_distance
  end

  def convert_split_distance!
    return unless self[:distance].present?
    temp_split = Split.new
    temp_split.distance = delete_field(:distance)
    self[:distance_from_start] = temp_split.distance_from_start
  end

  def map_keys!(map)
    map.each do |old_key, new_key|
      self[new_key] = delete_field(old_key) if attributes.respond_to?(old_key)
    end
  end

  def merge_attributes!(merging_attributes)
    merging_attributes.each { |key, value| self[key] = value }
  end

  def normalize_birthdate!
    return unless self[:birthdate].present?
    date = self[:birthdate].to_date
    case
    when date.year <= Date.today.year % 100
      self[:birthdate] = date + 2000.years
    when date.year <= Date.today.year % 100 + 100
      self[:birthdate] = date + 1900.years
    else
      self[:birthdate] = date
    end
  end

  def normalize_country_code!
    return unless self[:country_code].present?
    country_data = self[:country_code].to_s.downcase.strip
    country = Carmen::Country.coded(country_data) || Carmen::Country.named(country_data)
    self[:country_code] = country ? country.code : find_country_code_by_nickname(country_data)
  end

  def normalize_gender!
    return unless self[:gender].present?
    gender = self[:gender]
    self[:gender] = gender.downcase.start_with?('m') ? 'male' : 'female'
  end

  def normalize_state_code!
    return unless self[:state_code].present?
    state_data = self[:state_code].to_s.strip
    country = Carmen::Country.coded(self[:country_code])
    self[:state_code] =
        case
        when state_data.blank?
          nil
        when country.blank? || country.subregions.blank?
          state_data
        else
          subregion = country.subregions.coded(state_data) || country.subregions.named(state_data)
          subregion ? subregion.code : state_data
        end
  end

  def split_field!(old_field, first_field, second_field, split_char = ' ')
    return unless self[old_field].present?
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

  private

  def find_country_code_by_nickname(country_string)
    return nil if country_string.blank?
    country_code = I18n.t("nicknames.#{country_string}")
    country_code.include?('translation missing') ? nil : country_code
  end

  def params_class(model_name)
    "#{model_name.to_s.classify}Parameters".constantize
  end
end
