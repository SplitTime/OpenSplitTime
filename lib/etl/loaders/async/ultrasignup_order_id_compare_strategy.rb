# frozen_string_literal: true

module ETL::Loaders::Async
  # This loader does not attempt to persist records in the database.
  # It merely compares order ids and creates errors when differences exist.

  # TODO: This is a hack and should be replaced by a proper sync strategy
  class UltrasignupOrderIdCompareStrategy
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
      @errors = []
    end

    # @return [nil]
    def load_records
      custom_load
    end

    private

    attr_reader :proto_records, :options, :import_job

    # @return [nil]
    def custom_load
      ultrasignup_order_ids = proto_records.map { |pr| pr[:Order_ID].to_s }
      lottery_application_facts = organization.historical_facts.where(kind: :lottery_application)
      existing_order_ids = lottery_application_facts.pluck(:comments).compact.map { |comment| comment.split(": ").last }.compact

      missing_order_ids = ultrasignup_order_ids - existing_order_ids
      outdated_order_ids = existing_order_ids - ultrasignup_order_ids

      errors << orders_missing_error(missing_order_ids) if missing_order_ids.any?
      errors << orders_outdated_error(outdated_order_ids) if outdated_order_ids.any?
    end

    def organization
      import_job.parent
    end
  end
end
