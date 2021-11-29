# frozen_string_literal: true

module ETL
  module Transformers
    class JsonapiBatchStrategy < BaseTransformer
      def initialize(parsed_structs, options)
        @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
        @options = options
        @errors = []
        validate_setup
      end

      def transform
        return if errors.present?
        proto_records.each do |proto_record|
          proto_record.record_type = proto_record.delete_field(:type).to_sym
          proto_record.attributes_to_keys!
          transform_name_extensions!(proto_record)
          proto_record.slice_permitted!
          proto_record[parent_id_attribute] = parent.id if proto_record.record_class.attribute_names.include?(parent_id_attribute)
        end
        proto_records
      end

      def transform_name_extensions!(proto_record)
        if proto_record[:name_extension]
          proto_record[:bitkey] = SubSplit.bitkey(proto_record.delete_field(:name_extension))
        end
      end

      private

      attr_reader :proto_records

      def validate_setup
      end
    end
  end
end
