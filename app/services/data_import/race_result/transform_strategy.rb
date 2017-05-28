module DataImport::RaceResult
  class TransformStrategy
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
        transform_time_data!(proto_record)
        proto_record.record_type = :effort
        proto_record.map_keys!(EffortParameters.mapping)
        proto_record.normalize_gender!
        proto_record.split_field!(:full_name, :first_name, :last_name)
        proto_record.permit!(permitted_params)
        proto_record.merge_attributes!(global_attributes)
      end
      proto_records
    end

    private

    attr_reader :proto_records, :options

    def transform_time_data!(proto_record)
      extract_times!(proto_record)
      transform_times!(proto_record)
      create_children!(proto_record)
      mark_for_destruction!(proto_record)
    end

    def extract_times!(proto_record)
      times = time_keys.map { |key| proto_record.delete_field(key) }
      start_time = times.any?(&:present?) ? '0:00:00.00' : ''
      times.unshift(start_time) # RR does not include a start time with its data so we need to add one
      proto_record[:segment_times] = times
    end

    def transform_times!(proto_record)
      segment_seconds = proto_record[:segment_times].map { |hms_time| TimeConversion.hms_to_seconds(hms_time) }
      proto_record[:times_from_start] = segment_seconds.map.with_index do |time, i|
        segment_seconds[0..i].compact.sum.round(2) if time.present?
      end
    end

    def create_children!(proto_record)
      split_time_attributes = time_points.zip(proto_record[:times_from_start]).map do |time_point, time|
        {record_type: :split_time, lap: time_point.lap, split_id: time_point.split_id, sub_split_bitkey: time_point.bitkey, time_from_start: time}
      end
      split_time_attributes.each { |attributes| proto_record.children << ProtoRecord.new(attributes) }
    end

    def mark_for_destruction!(proto_record)
      proto_record.children.each do |child_record|
        child_record.record_action = :destroy if child_record[:time_from_start].blank?
      end
    end

    # Because of the way they are built, keys for all structs are identical,
    # so use the first as a template for all.
    def time_keys
      @time_keys ||= proto_records.first.to_h.keys
                         .select { |key| key.to_s.start_with?('section') }
                         .sort_by { |key| key[/\d+/].to_i }
    end

    def global_attributes
      {event_id: event.id, concealed: event.concealed}
    end

    def event
      options[:event]
    end

    def time_points
      @time_points ||= event.required_time_points
    end

    def permitted_params
      EffortParameters.permitted.to_set
    end

    def validate_setup
      errors << missing_event_error unless event.present?
      (errors << split_mismatch_error) if event.present? && !event.laps_unlimited? &&
          (time_keys.size != time_points.size - 1)
    end

    def missing_event_error
      {title: 'Event is missing',
       detail: {messages: ['This import requires that an event be provided']}}
    end

    def split_mismatch_error
      {title: 'Split mismatch error',
       detail: {messages: ["#{event} expects #{time_points.size - 1} time points (excluding the start split) " +
                               "but the json response contemplates #{time_keys.size} time points."]}}
    end
  end
end
