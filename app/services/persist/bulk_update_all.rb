# frozen_string_literal: true

module Persist

  # This class uses update_all to optimize updates wherein the number of records is large and the
  # universe of values for updated columns is small. For example, this class performs
  # well updating boolean and enum fields over many records.

  # Be careful! The #update_all method bypasses all callbacks and some database constraints,
  # such as foreign key constraints.

  class BulkUpdateAll < Persist::Base

    def post_initialize(options)
      @update_fields = options[:update_fields] && Array.wrap(options[:update_fields])
    end

    private

    def persist_resources
      grouped_resources.each do |value_pairs, selected_resources|
        next if errors.present?

        begin
          model.where(id: selected_resources).update_all(value_pairs)
        rescue ActiveRecord::ActiveRecordError => exception
          errors << active_record_error(exception)
        end

      end
    end

    def grouped_resources
      @grouped_resources ||= resources.group_by do |resource|
        update_fields.map { |field| [field, resource.send(field)] }.to_h
      end
    end

    def validate_additional_setup
      raise ArgumentError, 'update_fields must be provided' unless update_fields
    end
  end
end
