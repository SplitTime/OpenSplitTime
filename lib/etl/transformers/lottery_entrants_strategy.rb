# frozen_string_literal: true

module ETL
  module Transformers
    class LotteryEntrantsStrategy < BaseTransformer
      def initialize(parsed_structs, options)
        @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
        @options = options
        @errors = []
        validate_setup
      end

      def transform
        return if errors.present?

        proto_records.each do |proto_record|
          proto_record.underscore_keys!
          parameterized_division_name = proto_record.delete_field(:division).parameterize
          division = divisions_by_name[parameterized_division_name]

          if division.present?
            proto_record.transform_as(:lottery_entrant, division: division)
            proto_record.slice_permitted!
          else
            errors << division_not_found_error(parameterized_division_name)
          end
        end

        proto_records
      end

      private

      attr_reader :proto_records
      alias_method :lottery, :parent

      def divisions_by_name
        lottery.divisions.index_by { |division| division.name.parameterize }
      end

      def validate_setup
        errors << missing_parent_error unless lottery.present?
      end
    end
  end
end
