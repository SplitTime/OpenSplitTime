# frozen_string_literal: true

module ETL::Transformers
  class AdilasBearStrategy < BaseTransformer
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

    attr_reader :proto_record

    def transform_time_data
      sort_and_fill_times
      parse_times
      fix_negative_times
      proto_record.create_split_time_children!(time_points, time_attribute: :absolute_time)
      proto_record.set_split_time_stop! if proto_record[:dnf]
    end

    def sort_and_fill_times
      proto_record[:times_of_day] = (0..13).flat_map { |i| proto_record[:times][i] || %w(... ...) }
    end

    def parse_times
      proto_record[:times_of_day] = proto_record[:times_of_day].map { |time_string| ActiveSupport::TimeZone[time_zone].parse(time_string) }
    end

    # Some times are off by a full day behind, resulting in negative (invalid) times from start
    def fix_negative_times
      proto_record[:absolute_times] = proto_record[:times_of_day].map do |datetime|
        next unless datetime
        seconds = datetime - effort_start_time
        seconds_in_day = (1.day / 1.second)
        adjustment = seconds&.negative? ? (seconds.to_i / seconds_in_day).abs * seconds_in_day : 0
        datetime + adjustment
      end
    end

    def effort_start_time
      proto_record[:times_of_day].first
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

    def validate_setup
      errors << missing_event_error unless event.present?
    end
  end
end
