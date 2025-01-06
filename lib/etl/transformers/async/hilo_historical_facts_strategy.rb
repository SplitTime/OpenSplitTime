module Etl::Transformers::Async
  class HiloHistoricalFactsStrategy < Etl::Transformers::BaseTransformer
    PRIOR_OUTCOME_YEARS = (2017..2024).to_a.map { |year| "Result_#{year}".to_sym }.freeze
    PRIOR_APPLICATION_YEARS = (2020..2024).to_a.map { |year| "App_#{year}".to_sym }.freeze
    PRIOR_RESET_YEARS = (2020..2024).to_a.map { |year| "Reset_#{year}".to_sym }.freeze

    OUTCOMES = {
      :dnf => :dnf,
      :finish => :finished,
    }.with_indifferent_access.freeze

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
        record_current_year_application(struct)
        record_prior_year_outcomes(struct)
        record_prior_year_applications(struct)
        record_prior_year_resets(struct)
        record_legacy_ticket_count(struct)
        record_volunteer_hours(struct)
        record_trail_work_hours(struct)
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
    end

    def record_current_year_application(struct)
      value = struct[:"2025_App?"]

      if value.downcase == "yes"
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :lottery_application
        proto_record[:year] = 2025
        proto_record[:comments] = struct[:Reg_Number]

        proto_records << proto_record
      end
    end

    def record_prior_year_outcomes(struct)
      years_hash = struct.to_h.slice(*PRIOR_OUTCOME_YEARS)

      years_hash.each do |year_heading, outcome|
        year_outcome = OUTCOMES[outcome.downcase]

        if year_outcome.present?
          proto_record = base_proto_record.deep_dup
          proto_record[:kind] = year_outcome
          proto_record[:year] = year_heading.to_s.split("_").last.to_i

          proto_records << proto_record
        end
      end
    end

    def record_prior_year_applications(struct)
      years_hash = struct.to_h.slice(*PRIOR_APPLICATION_YEARS)

      years_hash.each do |year_heading, value|
        applied = value.downcase == "a"

        if applied
          proto_record = base_proto_record.deep_dup
          proto_record[:kind] = :lottery_application
          proto_record[:year] = year_heading.to_s.split("_").last.to_i

          proto_records << proto_record
        end
      end
    end

    def record_prior_year_resets(struct)
      years_hash = struct.to_h.slice(*PRIOR_RESET_YEARS)

      years_hash.each do |year_heading, value|
        reset = value.downcase == "r"

        if reset
          proto_record = base_proto_record.deep_dup
          proto_record[:kind] = :ticket_reset_legacy
          proto_record[:year] = year_heading.to_s.split("_").last.to_i

          proto_records << proto_record
        end
      end
    end

    def record_legacy_ticket_count(struct)
      count = struct[:Total_Count]

      if count.present?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :lottery_ticket_count_legacy
        proto_record[:year] = 2024

        proto_records << proto_record
      end
    end

    def record_volunteer_hours(struct)
      hours = struct[:Vol_Points]

      if hours.present? && hours.positive?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :volunteer_hours
        proto_record[:quantity] = hours

        proto_records << proto_record
      end
    end

    def record_trail_work_hours(struct)
      hours = struct[:TW_Boost]

      if hours.present? && hours.positive?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :trail_work_hours
        proto_record[:quantity] = hours

        proto_records << proto_record
      end
    end
  end
end
