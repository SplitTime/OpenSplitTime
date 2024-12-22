# frozen_string_literal: true

module Etl::Transformers::Async
  class HistoricalFactsStrategy < Etl::Transformers::BaseTransformer
    def initialize(parsed_structs, options)
      @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
      @options = options
      @import_job = options[:import_job]
      @errors = []
    end

    def transform
      return proto_records if errors.present?

      proto_records.each.with_index(1) do |proto_record, row_index|
        proto_record.underscore_keys!
        proto_record.transform_as(:historical_fact, organization: organization)
      rescue StandardError => e
        import_job.increment!(:failed_count)
        errors << transform_failed_error(e, row_index)
      end

      proto_records
    end

    private

    attr_reader :proto_records, :options, :import_job
  end
end
