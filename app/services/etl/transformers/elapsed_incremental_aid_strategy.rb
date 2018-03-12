# frozen_string_literal: true

module ETL::Transformers
  class ElapsedIncrementalAidStrategy
    include ETL::Errors
    attr_reader :errors

    def initialize(parsed_struct, options)
      @proto_record = ProtoRecord.new(parsed_struct)
      @options = options
      @errors = []
      validate_setup
    end

    def transform
      return if errors.present?
      transform_time_data
      proto_record.record_type = :effort
      proto_record.normalize_gender!
      proto_record.split_field!(:full_name, :first_name, :last_name)
      proto_record.add_country_from_state_code!
      proto_record.slice_permitted!
      proto_record.merge_attributes!(global_attributes)
      [proto_record]
    end

    private

    attr_reader :proto_record, :options

    def transform_time_data
      establish_split_order
      nullify_blanks
      add_missing_hours
      parse_times
      add_incremental_times
      calculate_times_from_start
      proto_record.create_split_time_children!(time_points)
      proto_record.set_split_time_stop!
    end

    def establish_split_order
      proto_record[:ordered_splits] = proto_record[:times].keys
    end

    def nullify_blanks
      proto_record[:times].transform_values! { |time_string| time_string.gsub(/\D/, '').blank? ? '' : time_string}
    end

    def add_missing_hours
      proto_record[:times].transform_values! do |time_string|
        time_string.split(':').size == 2 ? '00:' + time_string : time_string
      end
    end

    def parse_times
      proto_record[:integer_times] = proto_record[:times].transform_values { |time_string| TimeConversion.hms_to_seconds(time_string) }
    end

    def add_incremental_times
      base_names.each do |base_name|
        in_time = proto_record[:integer_times]["#{base_name} In"]
        out_time = proto_record[:integer_times]["#{base_name} Out"]
        proto_record[:integer_times]["#{base_name} Out"] = in_time + out_time if in_time && out_time
      end
    end

    def calculate_times_from_start
      proto_record[:times_from_start] = proto_record[:ordered_splits].map { |split| proto_record[:integer_times][split] }
      proto_record[:times_from_start].unshift(0) if proto_record[:times_from_start].any?(&:present?)
    end

    def global_attributes
      {event_id: event.id}
    end

    def time_points
      @time_points ||= event.required_time_points
    end

    def event
      options[:event]
    end

    def base_names
      proto_record[:times].keys.map { |split_name| split_name.gsub(/( In| Out)\z/, '') }.uniq
    end

    def validate_setup
      errors << missing_event_error unless event.present?
    end
  end
end
