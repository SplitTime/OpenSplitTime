module DataImport::Csv
  class TransformSplitsStrategy
    include DataImport::Errors
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
        proto_record.record_type = :split
        proto_record.map_keys!(SplitParameters.mapping)
        proto_record.permit!(SplitParameters.permitted.to_set)
        proto_record.merge_attributes!(global_attributes)
      end
      proto_records
    end

    private

    attr_reader :proto_records, :options

    def global_attributes
      {course_id: event.course.id}
    end

    def event
      options[:event]
    end

    def validate_setup
      errors << missing_event_error unless event.present?
    end
  end
end
