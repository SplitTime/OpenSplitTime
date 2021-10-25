# frozen_string_literal: true

module ETL
  module Loaders
    class AsyncInsertStrategy
      include ETL::Errors

      CHUNK_SIZE = 25

      attr_reader :errors

      def self.load_records(proto_records, import_job, options)
        new(proto_records, import_job, options).load_records
      end

      def initialize(proto_records, import_job, options)
        @proto_records = proto_records
        @import_job = import_job
        @options = options
        @errors = []
      end

      def load_records
        ActiveRecord::Base.transaction do
          custom_load
          raise ActiveRecord::Rollback if errors.present?
        end
      end

      private

      attr_reader :proto_records, :import_job, :options

      def custom_load
        proto_records.each.with_index(1) do |proto_record, row_index|
          if proto_record.record_class.blank?
            errors << invalid_proto_record_error(proto_record, row_index)
            next
          end

          record = build_record(proto_record)

          if record.save
            import_job.increment!(:success_count)
          else
            import_job.increment!(:failure_count)
            errors << resource_error_object(record, row_index)
          end

          import_job.touch if row_index % CHUNK_SIZE == 0
        end
      end

      def build_record(proto_record)
        return nil if proto_record.marked_for_destruction?

        model_class = proto_record.record_class
        attributes = proto_record.to_h
        record = model_class.new(attributes)
        assign_child_records(proto_record, record)
        record
      end

      def assign_child_records(proto_record, record)
        proto_record.children.each do |child_proto|
          next if child_proto.marked_for_destruction?

          child_relationship = child_proto.record_type.to_s.pluralize
          child_record = record.send(child_relationship).new
          child_record.assign_attributes(child_proto.to_h)
        end
      end
    end
  end
end
