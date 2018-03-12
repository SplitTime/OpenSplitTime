# frozen_string_literal: true

module ETL::Transformers
  class EffortsWithTimesStrategy
    include ETL::Errors
    attr_reader :errors

    TIME_ATTRIBUTE_MAP = {elapsed: :time_from_start, military: :military_time}

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

    attr_reader :proto_records, :options

    def transform_time_data!(proto_record)
      extract_times(proto_record)
      transform_times(proto_record)
      proto_record.create_split_time_children!(time_points, time_attribute: time_attribute)
      proto_record.set_split_time_stop!
      proto_record.set_effort_offset!(time_points.first)
    end

    def extract_times(proto_record)
      proto_record[:times] = time_keys.map { |key| proto_record.delete_field(key) }
    end

    def transform_times(proto_record)
      if time_format == :elapsed
        proto_record[:times_from_start] = proto_record[:times].map { |time_string| TimeConversion.hms_to_seconds(time_string) }
      elsif time_format == :military
        proto_record[:military_times] = proto_record[:times].map(&:presence)
      end
    end

    def time_keys
      @time_keys ||= attribute_keys.elements_after(start_key).unshift(start_key)
    end

    def time_format
      options[:time_format]&.to_sym || :elapsed
    end

    def event
      options[:event]
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

    def start_key
      attribute_keys.find { |key| key.to_s.start_with?('start') }
    end

    def validate_setup
      errors << missing_event_error unless event.present?
      return unless proto_records.present?
      errors << missing_start_key_error unless start_key
      (errors << split_mismatch_error(event, time_points.size, time_keys.size)) if event.present? && !event.laps_unlimited? &&
          (time_keys.size != time_points.size)
      errors << value_not_permitted_error(:time_format, TIME_ATTRIBUTE_MAP.keys, time_format) unless TIME_ATTRIBUTE_MAP.keys.include?(time_format)
    end
  end
end
