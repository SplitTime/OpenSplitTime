# frozen_string_literal: true

module ETL
  module Loaders
    # If no unique_key is provided, this is a plain insert loader that will
    # keep track of errors if validations are violated at the model or database
    # level.
    #
    # If a unique_key is provided, records having the same unique key as an existing
    # database record will be ignored.
    class AsyncInsertStrategy
      include ETL::Errors

      CHUNK_SIZE = 20

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
        @unique_key = options[:unique_key]
        @errors = []
      end

      # @return [nil]
      def load_records
        custom_load
      end

      private

      attr_reader :proto_records, :options, :import_job, :unique_key

      # @return [nil]
      def custom_load
        proto_records.each.with_index(1) do |proto_record, row_index|
          if proto_record.record_class.blank?
            errors << invalid_proto_record_error(proto_record, row_index)
            next
          end

          record = build_record(proto_record)

          if unique_key.present?
            unique_attributes = unique_key.map { |attr| [attr => record.send(attr)] }.to_h

            next if record.class.exists?(unique_attributes)
          end

          if record.save
            import_job.increment!(:succeeded_count)
          else
            import_job.increment!(:failed_count)
            errors << resource_error_object(record, row_index)
          end

        rescue ActiveRecord::ActiveRecordError => e
          import_job.increment!(:failed_count)
          errors << record_not_saved_error(e, row_index)
        ensure
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
