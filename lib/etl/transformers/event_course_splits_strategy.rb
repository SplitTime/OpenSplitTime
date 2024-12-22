# frozen_string_literal: true

module Etl
  module Transformers
    class EventCourseSplitsStrategy < BaseTransformer
      def initialize(parsed_structs, options)
        @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
        @options = options
        @import_job = options[:import_job]
        @errors = []
        validate_setup
      end

      def transform
        return proto_records if errors.present?

        proto_records.each.with_index(1) do |proto_record, row_index|
          proto_record.underscore_keys!
          proto_record.transform_as(:split, event: event)
          proto_record.slice_permitted!
        rescue StandardError => e
          import_job.increment!(:failed_count)
          errors << transform_failed_error(e, row_index)
        end

        proto_records
      end

      private

      attr_reader :proto_records, :import_job
      alias event parent

      def validate_setup
        errors << missing_parent_error("Event") unless event.present?
        errors << missing_records_error unless proto_records.present?
      end
    end
  end
end
