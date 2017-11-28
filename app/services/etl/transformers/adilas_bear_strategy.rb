module ETL::Transformers
  class AdilasBearStrategy
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
      proto_record.slice_permitted!
      proto_record.merge_attributes!(global_attributes)
      [proto_record]
    end

    private

    attr_reader :proto_record, :options

    def transform_time_data
      parse_times
      calculate_times_from_start
      proto_record[:start_offset] = effort_start_time - event.start_time
      create_children
      set_stop
    end

    def parse_times
      proto_record[:times] = proto_record[:times].map { |time_string| ActiveSupport::TimeZone[time_zone].parse(time_string) }
    end

    def calculate_times_from_start
      proto_record[:times_from_start] = proto_record[:times].map { |time| time && (time - effort_start_time) }
    end

    def create_children
      split_time_attributes = time_points.zip(proto_record[:times_from_start]).map do |time_point, time|
        {record_type: :split_time, lap: time_point.lap, split_id: time_point.split_id, sub_split_bitkey: time_point.bitkey, time_from_start: time}
      end
      split_time_attributes.each do |attributes|
        proto_record.children << ProtoRecord.new(attributes) if attributes[:time_from_start]
      end
    end

    def set_stop
      stopped_child_record = proto_record.children.last
      (stopped_child_record[:stopped_here] = true) if stopped_child_record
    end

    def effort_start_time
      proto_record[:times].first
    end

    def global_attributes
      {event_id: event.id}
    end

    def time_zone
      event.home_time_zone
    end

    def time_points
      @time_points ||= event.required_time_points
    end

    def event
      options[:event]
    end

    def validate_setup
      errors << missing_event_error unless event.present?
    end
  end
end
