# frozen_string_literal: true

module ETL::Transformers
  class CsvLiveTimesStrategy
    include ETL::Errors
    attr_reader :errors
    attr_writer :proto_records

    def initialize(parsed_structs, options)
      @parsed_structs = parsed_structs
      @options = options
      @errors = []
      validate_setup
    end

    def transform
      return if errors.present?
      self.proto_records = parsed_structs.flat_map { |struct| proto_records_from_struct(struct) }
      proto_records.each do |proto_record|
        proto_record.record_type = :live_time
        proto_record.underscore_keys!
        proto_record.map_keys!(LiveTimeParameters.mapping)
        proto_record.slice_permitted!
        proto_record.merge_attributes!(global_attributes)
      end
      proto_records
    end

    private

    attr_reader :parsed_structs, :options, :proto_records

    def proto_records_from_struct(struct)
      records = [proto_record_in(struct), proto_record_out(struct)]
                    .reject { |pr| [pr[:military_time], pr[:with_pacer]].none?(&:present?) }
      records.last[:stopped_here] = struct.stopped_here if records.last
      records
    end

    def proto_record_in(struct)
      ProtoRecord.new(bib_number: struct.bib_number, military_time: struct.time_in, bitkey: 1, with_pacer: struct.pacer_in, stopped_here: false)
    end

    def proto_record_out(struct)
      ProtoRecord.new(bib_number: struct.bib_number, military_time: struct.time_out, bitkey: 64, with_pacer: struct.pacer_out, stopped_here: false)
    end

    def global_attributes
      {event_id: event.id, split_id: split.id}
    end

    def event
      options[:event]
    end

    def split
      options[:split]
    end

    def validate_setup
      errors << missing_event_error unless event.present?
      errors << missing_split_error unless split.present?
    end
  end
end
