# frozen_string_literal: true

module ETL::Transformers
  class EffortsWithTimesStrategy < BaseTransformer
    DEFAULT_START_KEY = 'start'
    TIME_ATTRIBUTE_MAP = {elapsed: :absolute_time, military: :military_time}

    def initialize(parsed_structs, options)
      @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
      @options = options
      @errors = []
      validate_setup
    end

    def transform
      return if errors.present?
      proto_records.each do |proto_record|
        proto_record.transform_as(:effort, event: event)
        transform_time_data!(proto_record)
        proto_record.slice_permitted!
      end
      proto_records
    end

    private

    attr_reader :proto_records

    def transform_time_data!(proto_record)
      add_missing_start_keys(proto_record)
      fill_missing_start_times(proto_record)
      extract_times(proto_record)
      transform_times(proto_record)
      proto_record.create_split_time_children!(time_points, time_attribute: time_attribute)
      proto_record.set_split_time_stop!
    end

    def add_missing_start_keys(proto_record)
      unless proto_record.has_key?(guaranteed_start_key)
        proto_record[guaranteed_start_key] = nil
      end
    end

    def fill_missing_start_times(proto_record)
      if missing_start_time?(proto_record)
        proto_record[guaranteed_start_key] = default_start_value
      end
    end

    def extract_times(proto_record)
      proto_record[:times] = time_keys.map { |key| proto_record.delete_field(key) }
    end

    def transform_times(proto_record)
      if time_format == :elapsed
        proto_record[:absolute_times] = proto_record[:times].map do |time_string|
          seconds = TimeConversion.hms_to_seconds(time_string)
          seconds ? event.scheduled_start_time + seconds : nil
        end
      elsif time_format == :military
        proto_record[:military_times] = proto_record[:times].map(&:presence)
      end
    end

    def guaranteed_start_key
      @guaranteed_start_key ||= start_key || DEFAULT_START_KEY
    end

    def time_keys
      @time_keys ||= finish_times_only? ? [DEFAULT_START_KEY, finish_key] : attribute_keys.elements_after(start_key, inclusive: true)
    end

    def time_format
      options[:time_format]&.to_sym || :elapsed
    end

    def time_attribute
      TIME_ATTRIBUTE_MAP[time_format]
    end

    def time_points
      @time_points ||= event.required_time_points.presence || event.cycled_time_points
    end

    # Assume keys are identical for all structs, so use the first as a template for all.
    def attribute_keys
      @attribute_keys ||= proto_records.first.to_h.keys.map { |key| key.to_s.underscore.to_sym }
    end

    def missing_start_time?(proto_record)
      proto_record[guaranteed_start_key].blank? && time_keys.map { |key| proto_record[key].presence }.compact.present?
    end

    def start_key
      @start_key ||= attribute_keys.find { |key| key.to_s.start_with?('start') }
    end

    def finish_key
      @finish_key ||= attribute_keys.find { |key| key.to_s.start_with?('finish') || key.to_s.start_with?('time') }
    end

    def default_start_value
      case time_format
      when :elapsed
        '00:00:00'
      else
        TimeConversion.absolute_to_hms(event.scheduled_start_time_local)
      end
    end

    def finish_times_only?
      start_key.nil? && finish_key.present?
    end

    def validate_setup
      errors << missing_event_error unless event.present?
      return unless proto_records.present?
      errors << value_not_permitted_error(:time_format, TIME_ATTRIBUTE_MAP.keys, time_format) unless TIME_ATTRIBUTE_MAP.keys.include?(time_format)
      return if finish_times_only?

      errors << missing_start_key_error unless start_key
      (errors << split_mismatch_error(event, time_points.size, time_keys.size)) if event.present? && !event.laps_unlimited? &&
        (time_keys.size != time_points.size)
    end
  end
end
