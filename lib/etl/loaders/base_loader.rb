# frozen_string_literal: true

module ETL
  module Loaders
    class BaseLoader
      include ETL::Errors
      attr_reader :saved_records, :invalid_records, :destroyed_records, :ignored_records, :errors

      def initialize(proto_records, options)
        @proto_records = proto_records
        @options = options
        @saved_records = []
        @invalid_records = []
        @destroyed_records = []
        @ignored_records = []
        @errors = []
        validate_setup
        post_initialize(options)
      end

      def load_records
        return if errors.present?
        ActiveRecord::Base.transaction do
          custom_load
          raise ActiveRecord::Rollback if invalid_records.present?
        end
      end

      private

      attr_reader :proto_records, :options

      def post_initialize(options) end

      def validate_setup
        proto_records.each do |proto_record|
          errors << invalid_proto_record_error(proto_record) unless proto_record.record_class
        end
      end
    end
  end
end
