module DataImport::RaceResult
  class TransformStrategy
    include Transformable
    attr_reader :errors

    def initialize(parsed_structs, options)
      @parsed_structs = parsed_structs
      @options = options
      @errors = []
      validate_parsed_structs
    end

    def transform
      return if errors.present?
      map_keys!(:effort)
      normalize_gender!
      split_full_name!
      transform_time_data!
      permit!(permitted_params)
      merge_global_attributes!
    end

    private

    attr_reader :parsed_structs, :options

    def transform_time_data!
      parsed_structs.each do |struct|
        extract_times!(struct)
        transform_times!(struct)
        create_child_structs!(struct)
      end
    end

    def extract_times!(struct)
      times = time_keys.map { |key| struct.delete_field(key) }
      start_time = times.any?(&:present?) ? '0:00:00.00' : ''
      times.unshift(start_time) # RR does not include a start time with its data so we need to add one
      struct.segment_times = times
    end

    def transform_times!(struct)
      segment_seconds = struct.segment_times.map { |hms_time| TimeConversion.hms_to_seconds(hms_time) }
      struct.times_from_start = segment_seconds.map.with_index do |time, i|
        segment_seconds[0..i].sum.round(2) if time.present?
      end
    end

    def create_child_structs!(struct)
      split_time_attributes = time_points.zip(struct.times_from_start).map do |time_point, time|
        {record_type: :split_time, lap: time_point.lap, split_id: time_point.split_id, sub_split_bitkey: time_point.bitkey, time_from_start: time}
      end
      struct.child_structs = split_time_attributes.map { |attributes| OpenStruct.new(attributes) }
    end

    # Because of the way they are built, keys for all structs are identical,
    # so use the first as a template for all.
    def time_keys
      @time_keys ||= parsed_structs.first.to_h.keys
                         .select { |key| key.to_s.start_with?('section') }
                         .sort_by { |key| key[/\d+/].to_i }
    end

    def global_attributes
      {record_type: :effort, event_id: event.id, concealed: event.concealed}
    end

    def event
      options[:event]
    end

    def time_points
      @time_points ||= event.required_time_points
    end

    def permitted_params
      EffortParameters.permitted.to_set << :child_structs
    end

    def validate_parsed_structs
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
