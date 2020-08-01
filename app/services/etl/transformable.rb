# frozen_string_literal: true

module ETL::Transformable

  def add_country_from_state_code!
    state_code = self[:state_code]
    return unless state_code&.size == 2
    %w(US CA).each do |country_code|
      self[:country_code] = country_code if Carmen::Country.coded(country_code).subregions.map(&:code).include?(state_code)
    end
  end

  def add_date_to_time!(attribute, date)
    time_string = self[attribute]
    return unless time_string.present? && time_string =~ TimeConversion::MILITARY_FORMAT

    self[attribute] = "#{date.to_date.to_s} #{time_string}"
  end

  def align_split_distance!(split_distances)
    return unless self[:distance_from_start].present?
    match_threshold = 10
    matching_distance = split_distances.find do |distance|
      (distance - self[:distance_from_start]).abs < match_threshold
    end
    self[:distance_from_start] = matching_distance if matching_distance
  end

  def attributes_to_keys!
    self[:attributes].each { |key, value| self[key.underscore] = value }
  end

  def convert_start_offset!(event_start_time)
    return unless has_key?(:start_offset)
    start_offset = self[:start_offset].to_s.gsub(/[^\d:-]/, '')
    return unless start_offset.present?

    seconds = start_offset =~ TimeConversion::HMS_FORMAT ? TimeConversion.hms_to_seconds(start_offset) : start_offset.to_i
    self[:scheduled_start_time] ||= event_start_time + seconds
  end

  def convert_split_distance!
    return unless self[:distance].present?
    temp_split = Split.new
    temp_split.distance = delete_field(:distance)
    self[:distance_from_start] = temp_split.distance_from_start
  end

  def create_country_from_state!
    return unless self[:state_code].present? && self[:country_code].blank?
    attempt_codes = %w[US CA]
    self[:country_code] = attempt_codes.find do |code|
      Carmen::Country.coded(code).subregions.map(&:code).include?(self[:state_code])
    end
  end

  def create_split_time_children!(time_points, options = {})
    time_attribute = options[:time_attribute] || :time_from_start
    times_array = time_attribute.to_s.sub('time', 'times').to_sym

    split_time_attributes = self[times_array].zip(time_points).select(&:last).map.with_index do |(time, time_point), i|
      {record_type: :split_time, lap: time_point.lap, split_id: time_point.split_id, sub_split_bitkey: time_point.bitkey, time_attribute => time, imposed_order: i}
    end

    split_time_attributes.each do |attributes|
      if attributes[time_attribute] || options[:preserve_nils]
        self.children << ProtoRecord.new(attributes)
      end
    end
  end
  
  def delete_nil_keys!(*keys)
    existing_keys = self.to_h.keys.to_set
    keys.each do |key|
      if existing_keys.include?(key) && self[key].nil?
        self.delete_field(key)
      end
    end
  end

  def fill_blank_values!(attributes)
    existing_keys = self.to_h.keys.to_set
    attributes.each do |key, value|
      if existing_keys.include?(key)
        self[key] = value if self[key].blank?
      end
    end
  end

  def localize_datetime!(local_key, utc_key, time_zone_name)
    return unless has_key?(local_key)
    local_time = delete_field(local_key) || ''
    time_zone = ActiveSupport::TimeZone[time_zone_name || '']
    parsed_time = time_zone&.parse(local_time)&.in_time_zone('UTC')
    self[utc_key] = parsed_time if parsed_time
  end

  def map_keys!(map)
    map.each do |old_key, new_key|
      self[new_key] = delete_field(old_key) if attributes.respond_to?(old_key)
    end
  end

  def merge_attributes!(merging_attributes)
    merging_attributes.each { |key, value| self[key] = value }
  end

  def normalize_country_code!
    return unless self[:country_code].present?
    country_data = self[:country_code].to_s.downcase.strip
    country = Carmen::Country.coded(country_data) || Carmen::Country.named(country_data)
    self[:country_code] = country ? country.code : find_country_code_by_nickname(country_data)
  end

  def normalize_date!(attribute)
    date = self[attribute].to_date
    self[attribute] = modernize_date(date).to_s
  rescue NoMethodError, ArgumentError
    # Do not attempt to transform the date
  end

  def normalize_datetime!(attribute)
    datetime = self[attribute].to_datetime
    self[attribute] = modernize_date(datetime).strftime('%Y-%m-%d %H:%M:%S')
  rescue NoMethodError, ArgumentError
    # Do not attempt to transform the datetime
  end

  def normalize_gender!
    return unless self.has_key?(:gender)
    if self[:gender].presence.respond_to?(:downcase)
      self[:gender] = case self[:gender].downcase.first
                      when 'm' then 'male'
                      when 'f' then 'female'
                      else nil
                      end
    else
      self[:gender] = nil
    end
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

  def set_split_time_stop!
    stopped_child_record = children.reverse.find { |pr| pr[:absolute_time].present? }
    (stopped_child_record[:stopped_here] = true) if stopped_child_record
  end

  def slice_permitted!(permitted_params = nil)
    permitted_params ||= params_class.permitted.to_set
    to_h.keys.each do |key|
      delete_field(key) unless permitted_params.include?(key)
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

  def strip_white_space!
    to_h.each do |k, v|
      next unless v.respond_to?(:strip)
      self[k] = v.strip.presence || v.presence
    end
  end

  def underscore_keys!
    to_h.keys.each do |key|
      underscored_key = key.to_s.underscore.to_sym
      self[underscored_key] = delete_field(key) if underscored_key != key
    end
  end

  private

  def find_country_code_by_nickname(country_string)
    return nil if country_string.blank?
    country_code = I18n.t("nicknames.#{country_string}")
    country_code.include?('translation missing') ? nil : country_code
  end

  def modernize_date(date)
    case
    when date.year <= Date.today.year % 100
      date + 2000.years
    when date.year <= Date.today.year % 100 + 100
      date + 1900.years
    else
      date
    end
  end
end
