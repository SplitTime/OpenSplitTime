module Etl::Transformers::Async
  class UltrasignupHistoricalFactsStrategy < Etl::Transformers::BaseTransformer
    JUNK_VALUES = ["no", "n", "n/a", "na", "none"].freeze
    PRIOR_YEAR_OUTCOMES = {
      dns: :dns,
      dnf: :dnf,
      f: :finished,
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
        record_lottery_application(struct)
        record_volunteer_reported(struct)
        record_current_qualifier(struct)
        record_emergency_contact(struct)
        record_previous_names(struct)
        record_ever_finished(struct)
        record_dns_since_finish(struct)
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
      base_proto_record[:year] = struct[:Registration_Date].to_date.year
    end

    def record_lottery_application(_struct)
      proto_record = base_proto_record.deep_dup
      proto_record[:kind] = :lottery_application
      proto_record[:comments] = "Ultrasignup"

      proto_records << proto_record
    end

    def record_volunteer_reported(struct)
      years_count = struct[:Years_volunteered]

      if years_count.present? && years_count.positive?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :volunteer_multi_reported
        proto_record[:quantity] = years_count
        proto_record[:comments] = struct[:Description_of_Hardrock_volunteering]

        proto_records << proto_record
      end
    end

    def record_current_qualifier(struct)
      reported_qualifier = struct[:"Please_select_the_qualifier_you_finished."]

      if reported_qualifier.present?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :qualifier_finish
        proto_record[:comments] = reported_qualifier

        proto_records << proto_record
      end
    end

    def record_emergency_contact(struct)
      emergency_contact = struct[:emergency_name].to_s.downcase.in?(JUNK_VALUES) ? nil : struct[:emergency_name]
      emergency_phone = struct[:emergency_phone].to_s.downcase.in?(JUNK_VALUES) ? nil : struct[:emergency_phone]

      if emergency_contact.present? || emergency_phone.present?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :emergency_contact
        proto_record[:comments] = [emergency_contact.presence, emergency_phone.presence].compact.join(", ")

        proto_records << proto_record
      end
    end

    def record_previous_names(struct)
      names_1 = struct[:Name_Verification_for_Hardrock]
      names_2 = struct[:Name_Verification_for_Qualifier]
      names_2 = nil if names_2.to_s.downcase.strip == names_1.to_s.downcase.strip
      previous_names_array = [names_1, names_2]

      previous_names_array.each do |previous_names|
        if previous_names.present?
          next if name_is_junk(previous_names) || name_is_identical(previous_names, struct)

          proto_record = base_proto_record.deep_dup
          proto_record[:kind] = :previous_name
          proto_record[:comments] = previous_names

          proto_records << proto_record
        end
      end
    end

    def name_is_junk(previous_names)
      previous_names.downcase.strip.in? JUNK_VALUES
    end

    def name_is_identical(previous_names, struct)
      previous_names.downcase.strip == "#{struct[:First_Name]} #{struct[:Last_Name]}".downcase.strip
    end

    def record_ever_finished(struct)
      reported_ever_finished = struct[:Have_you_ever_finished_the_Hardrock_100]

      unless reported_ever_finished.blank?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :ever_finished
        proto_record[:comments] = reported_ever_finished.to_s.downcase

        proto_records << proto_record
      end
    end

    def record_dns_since_finish(struct)
      reported_dns_since_finish = struct[:Past_applications_since_running_Hardrock]

      if reported_dns_since_finish.present? && reported_dns_since_finish.to_s.numeric?
        proto_record = base_proto_record.deep_dup
        proto_record[:kind] = :dns_since_finish
        proto_record[:quantity] = reported_dns_since_finish

        proto_records << proto_record
      end
    end
  end
end
