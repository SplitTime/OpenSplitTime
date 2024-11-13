# frozen_string_literal: true

module ETL::Transformers::Async
  class HardrockHistoricalFactsStrategy < ETL::Transformers::BaseTransformer
    PRIOR_YEARS = (1992..2024).to_a.map { |year| year.to_s.to_sym }.freeze

    def initialize(parsed_structs, options)
      @initial_proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
      @options = options
      @import_job = options[:import_job]
      @proto_records = []
      @errors = []
    end

    def transform
      return initial_proto_records if errors.present?

      initial_proto_records.each.with_index(1) do |proto_record, row_index|
        initial_transform(proto_record)
        expand_dns(proto_record)
      rescue StandardError => e
        import_job.increment!(:failed_count)
        errors << transform_failed_error(e, row_index)
      end

      proto_records
    end

    private

    attr_reader :initial_proto_records, :options, :import_job, :proto_records

    def initial_transform(proto_record)
      proto_record.underscore_keys!
      proto_record.transform_as(:historical_fact)
    end

    def expand_dns(proto_record)
      dns_years = proto_record.to_h.slice(*PRIOR_YEARS).select { |_, val| val == "DNS" }.keys.map(&:to_s)
      dns_years.each do |year|
        proto_records << ProtoRecord.new(record_type: "HistoricalFact", kind: :dns, comments: year)
      end
    end
  end
end
