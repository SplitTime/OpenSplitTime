# frozen_string_literal: true

module ETL
  module Transformers
    class LotteryEntrantsStrategy < BaseTransformer
      def initialize(parsed_structs, options)
        @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
        @options = options
        @import_job = options[:import_job]
        @errors = []
        validate_setup
      end

      def transform
        return proto_records if errors.present?

        proto_records.each.with_index(1) do |proto_record, row_index|
          proto_record.underscore_keys!
          parameterized_division_name = proto_record.delete_field(:division_name)&.parameterize
          division = divisions_by_name[parameterized_division_name]

          if division.present?
            begin
              proto_record.transform_as(:lottery_entrant, division: division)
              proto_record.slice_permitted!
            rescue StandardError => e
              import_job.increment!(:failure_count)
              errors << transform_failed_error(e, row_index)
            end
          else
            import_job.increment!(:failure_count)
            errors << resource_not_found_error(::LotteryDivision, parameterized_division_name, row_index)
          end
        end

        proto_records
      end

      private

      attr_reader :proto_records, :import_job
      alias lottery parent

      def divisions_by_name
        lottery.divisions.index_by { |division| division.name.parameterize }
      end

      def validate_setup
        errors << missing_parent_error("Lottery") unless lottery.present?
        errors << missing_records_error unless proto_records.present?

        if proto_records.present?
          unless proto_records.first.keys.map { |key| key.to_s.underscore }.include?("division_name")
            errors << missing_key_error("Division name")
          end
        end
      end
    end
  end
end
