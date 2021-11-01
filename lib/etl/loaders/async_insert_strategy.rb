# frozen_string_literal: true

module ETL
  module Loaders
    class AsyncInsertStrategy
      include ETL::Errors

      CHUNK_SIZE = 100

      attr_reader :errors

      # @param [Array<ProtoRecord>] proto_records
      # @param [Hash] options
      # @return [nil]
      def self.load_records(proto_records, options)
        new(proto_records, options).load_records
      end

      # @param [Array<ProtoRecord>] proto_records
      # @param [Hash] options
      def initialize(proto_records, options)
        @proto_records = proto_records
        @options = options
        @import_job = options[:import_job]
        @errors = []
      end

      # @return [nil]
      def load_records
        ActiveRecord::Base.transaction do
          custom_load
          raise ActiveRecord::Rollback if errors.present?
        end
      end

      private

      attr_reader :proto_records, :options, :import_job

      # @return [nil]
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

          import_job.set_elapsed_time!
          import_job.touch if row_index % CHUNK_SIZE == 0
        end

        nil
      end

      # @param [ProtoRecord] proto_record
      # @return [::ApplicationRecord]
      def build_record(proto_record)
        model_class = proto_record.record_class
        attributes = proto_record.to_h
        record = model_class.new(attributes)
        assign_child_records(proto_record, record)
        record
      end

      # @param [ProtoRecord] proto_record
      # @param [::ApplicationRecord] record
      # @return [Array<ProtoRecord>]
      def assign_child_records(proto_record, record)
        proto_record.children.each do |child_proto|
          child_relationship = child_proto.record_type.to_s.pluralize
          child_record = record.send(child_relationship).new
          child_record.assign_attributes(child_proto.to_h)
        end
      end
    end
  end
end
