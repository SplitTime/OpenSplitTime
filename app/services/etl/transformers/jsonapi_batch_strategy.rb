# frozen_string_literal: true

module ETL::Transformers
  class JsonapiBatchStrategy
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
        proto_record.record_type = proto_record.delete_field(:type).to_sym
        proto_record.attributes_to_keys!
        transform_name_extensions!(proto_record)
        proto_record.slice_permitted!
        proto_record[:event_id] = event.id if proto_record.record_class.attribute_names.include?('event_id')
      end
      proto_records
    end

    def transform_name_extensions!(proto_record)
      if proto_record[:name_extension]
        proto_record[:bitkey] = SubSplit.bitkey(proto_record.delete_field(:name_extension))
      end
    end

    private

    attr_reader :proto_records, :options

    def event
      options[:event]
    end

    def validate_setup
    end
  end
end
