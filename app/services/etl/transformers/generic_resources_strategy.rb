# frozen_string_literal: true

module ETL::Transformers
  class GenericResourcesStrategy
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
        proto_record.transform_as(model, event: event)
        proto_record.slice_permitted!
      end
      proto_records
    end

    private

    attr_reader :proto_records, :options

    def event
      options[:event]
    end

    def model
      options[:model].to_sym
    end

    def validate_setup
      errors << missing_event_error unless event.present?
    end
  end
end
