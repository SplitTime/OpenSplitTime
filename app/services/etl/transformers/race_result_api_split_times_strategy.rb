# frozen_string_literal: true

module ETL::Transformers
  class RaceResultApiSplitTimesStrategy < BaseTransformer
    def initialize(parsed_structs, options)
      @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
      @options = options
      @errors = []
      validate_setup
    end

    def transform
      return if errors.present?
      proto_records.each do |proto_record|
        transform_time_data!(proto_record)
        proto_record.record_type = :effort
        proto_record.map_keys!({name: :full_name, sex: :gender, bib: :bib_number})
        proto_record.normalize_gender!
        proto_record.split_field!(:full_name, :first_name, :last_name)
        proto_record.slice_permitted!
        proto_record.merge_attributes!(global_attributes)
      end
      proto_records
    end

    private

    attr_reader :proto_records

    def transform_time_data!(proto_record)
      extract_times!(proto_record)
      transform_times!(proto_record)
      proto_record.create_split_time_children!(time_points, time_attribute: :absolute_time, preserve_nils: preserve_nils?)
      mark_for_destruction!(proto_record)
      set_stop!(proto_record)
    end

    def extract_times!(proto_record)
      proto_record[:times_of_day] = time_keys.map { |key| proto_record.delete_field(key) }
    end

    def transform_times!(proto_record)
      proto_record[:absolute_times] = proto_record[:times_of_day].map do |time|
        next unless time.present?
        seconds = ActiveSupport::TimeZone[event.home_time_zone].parse(time).seconds_since_midnight
        event.start_time_local.at_midnight + seconds
      end
    end

    def mark_for_destruction!(proto_record)
      proto_record.children.each do |child_record|
        child_record.record_action = :destroy if child_record[:absolute_time].blank?
      end
    end

    def set_stop!(proto_record)
      stop_indicators = %w(DNF DSQ)
      if stop_indicators.include?(proto_record[:status])
        stopped_child_record = proto_record.children.reverse.find { |pr| pr[:absolute_time].present? }
        (stopped_child_record[:stopped_here] = true) if stopped_child_record
      end
    end

    # Because of the way they are built, keys for all structs are identical,
    # so use the first as a template for all.
    def time_keys
      @time_keys ||= proto_records.first.to_h.keys
                         .select { |key| key.to_s.start_with?('time_') }
                         .sort_by { |key| key[/\d+/].to_i }
    end

    def global_attributes
      {event_id: event.id}
    end

    def time_points
      @time_points ||= event.required_time_points
    end
    
    def preserve_nils?
      options[:delete_blank_times]
    end

    def validate_setup
      errors << missing_event_error unless event.present?
      (errors << split_mismatch_error(event, time_points.size, time_keys.size)) if event.present? && !event.laps_unlimited? &&
          (time_keys.size != time_points.size)
    end
  end
end
