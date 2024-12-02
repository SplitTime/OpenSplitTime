# frozen_string_literal: true

module ETL::Transformers::Async
  class NullStrategy < ETL::Transformers::BaseTransformer
    def initialize(parsed_structs, options)
      @parsed_structs = parsed_structs
      @options = options
      @import_job = options[:import_job]
      @proto_records = []
      @errors = []
    end

    def transform
      return [] if errors.present?

      parsed_structs.each.with_index(1) do |struct, row_index|
        proto_records << ProtoRecord.new(**struct.to_h)
      rescue StandardError => e
        import_job.increment!(:failed_count)
        errors << transform_failed_error(e, row_index)
      end

      proto_records
    end

    private

    attr_reader :parsed_structs, :options, :import_job, :proto_records

  end
end
