module ETL::Transformers
  class EffortsWithTimesStrategy
    include ETL::Errors
    attr_reader :errors

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
      proto_record.create_split_time_children!(time_points)
      proto_record.set_split_time_stop!
      proto_record.set_effort_offset!(time_points.first)
    end

    def extract_times(proto_record)
      proto_record[:times] = time_keys.map { |key| proto_record.delete_field(key) }
    end

    def transform_times(proto_record)
      proto_record[:times_from_start] = proto_record[:times].map { |time_string| TimeConversion.hms_to_seconds(time_string) }
    end

    def time_keys
      @time_keys ||= attribute_keys.elements_after(start_key).unshift(start_key)
    end

    def event
      options[:event]
    end

    def time_points
      @time_points ||= event.required_time_points
    end

    # Assume the first provided effort has a full set of times,
    # so use the first as a template for all.

    def attribute_keys
      @attribute_keys ||= proto_records.first.to_h.keys.map { |key| key.to_s.underscore.to_sym }
    end

    def start_key
      attribute_keys.find { |key| key.to_s.start_with?('start') }
    end

    def validate_setup
      errors << missing_event_error unless event.present?
      errors << missing_start_key_error unless start_key
      (errors << split_mismatch_error(event, time_points.size, time_keys.size)) if event.present? && !event.laps_unlimited? &&
          (time_keys.size != time_points.size)
    end
  end
end
