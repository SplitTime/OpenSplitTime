# frozen_string_literal: true

module ETL::Loaders
  class UpsertStrategy < BaseLoader

    def post_initialize(options)
      @unique_key = options[:unique_key]&.map { |attribute| attribute.to_s.underscore.to_sym }
    end

    def custom_load
      proto_records.each do |proto_record|
        record = record_from_proto(proto_record)
        next unless record

        if record.new_record? || record.changed?
          upsert(record)
        else
          ignored_records << record
        end
      end
    end

    private

    attr_reader :unique_key

    def record_from_proto(proto_record)
      record = fetch_record(proto_record)
      eliminate(record) and return nil if proto_record.record_action == :destroy
      record
    end

    def fetch_record(proto_record)
      model_class = proto_record.record_class
      attributes = proto_record.resource_attributes(unique_key)
      unique_attributes = attributes.slice(*unique_key)
      record = unique_key_valid?(unique_key, unique_attributes) ?
                   model_class.find_or_initialize_by(unique_attributes) :
                   model_class.new
      record.assign_attributes(attributes)
      record
    end

    def eliminate(record)
      if record.new_record?
        ignored_records << record
      else
        begin
          destroyed_records << record if record.destroy
        rescue ActiveRecord::ActiveRecordError => exception
          record.errors.add(exception)
          invalid_records << record
        end
      end
    end

    def upsert(record)
      add_audit_attributes(record)
      if record.save
        saved_records << record
      else
        errors << jsonapi_error_object(record)
        invalid_records << record
      end
    end

    def unique_key_valid?(unique_key, unique_attributes)
      unique_key.present? && unique_key.size == unique_attributes.size && unique_attributes.values.none?(&:nil?)
    end
  end
end
