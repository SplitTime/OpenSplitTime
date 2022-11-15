# frozen_string_literal: true

module ETL
  module Transformers
    class EventGroupEntrantsStrategy < BaseTransformer
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
          event = single_event

          if event.nil?
            parameterized_event_name = proto_record.has_key?(:event_name) ? proto_record.delete_field(:event_name)&.to_s&.parameterize : nil
            event = events_by_short_name[parameterized_event_name]
          end

          if event.present?
            proto_record.transform_as(:effort, event: event)
            proto_record.slice_permitted!
          else
            import_job.increment!(:failed_count)
            errors << resource_not_found_error(::Event, parameterized_event_name, row_index)
          end
        rescue StandardError => e
          import_job.increment!(:failed_count)
          errors << transform_failed_error(e, row_index)
        end

        proto_records
      end

      private

      attr_reader :proto_records, :import_job
      alias event_group parent

      def events_by_short_name
        event_group.events.index_by { |event| event.short_name.parameterize }
      end

      def single_event
        return @single_event if defined?(@single_event)

        @single_event = event_group.multiple_events? ? nil : event_group.first_event
      end

      def validate_setup
        errors << missing_parent_error("EventGroup") unless event_group.present?
        errors << missing_records_error unless proto_records.present?

        return if errors.present? || single_event.present?

        unless proto_records.first.keys.map { |key| key.to_s.underscore }.include?("event_name")
          errors << missing_key_error("Event name")
        end
      end
    end
  end
end
