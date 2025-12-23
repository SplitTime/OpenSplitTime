module Etl::Transformers::Async
  class BearHistoricalFactsStrategy < Etl::Transformers::BaseTransformer
    JUNK_VALUES = ["no", "n", "n/a", "na", "none"].freeze

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
        set_base_proto_record(struct)
        record_lottery_application(struct)
        record_ever_finished(struct)
        record_reported_ticket_count(struct)
      rescue StandardError => e
        import_job.increment!(:failed_count)
        errors << transform_failed_error(e, row_index)
      end

      proto_records
    end

    private

    attr_reader :parsed_structs, :options, :import_job, :proto_records
    attr_accessor :base_proto_record

    def set_base_proto_record(struct)
      self.base_proto_record = ProtoRecord.new(**struct.to_h)

      base_proto_record.transform_as(:historical_fact, organization: organization)
      base_proto_record[:year] = 2025
    end

    def record_lottery_application(_struct)
      proto_record = base_proto_record.deep_dup
      proto_record[:kind] = :lottery_application
      proto_record[:comments] = "Ultrasignup"

      proto_records << proto_record
    end

    def record_ever_finished(struct)
      reported_ever_finished = struct[:Ever_finished]

      unless reported_ever_finished.blank?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :ever_finished
        proto_record[:comments] = reported_ever_finished.to_s.downcase

        proto_records << proto_record
      end
    end

    def record_reported_ticket_count(struct)
      reported_ticket_count = struct[:Reported_tickets]

      if reported_ticket_count.present? && reported_ticket_count.to_s.numeric?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :ticket_count_reported
        proto_record[:quantity] = reported_ticket_count

        proto_records << proto_record
      end
    end
  end
end
