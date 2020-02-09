# frozen_string_literal: true

module ETL::Loaders
  class UpsertStrategy < BaseLoader

    def post_initialize(options)
      @unique_key = options[:unique_key]&.map { |attribute| attribute.to_s.underscore.to_sym }
      @parent = options[:parent]
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

    attr_reader :unique_key, :parent

    def record_from_proto(proto_record)
      record = fetch_record(proto_record)
      eliminate(record) and return nil if proto_record.record_action == :destroy
      record
    end

    def fetch_record(proto_record)
      plural_model_class = proto_record.record_type.to_s.pluralize
      temp_resource = parent.send(plural_model_class).new
      temp_resource.assign_attributes(proto_record.to_h) # Use the class to cast attributes and convert virtual attributes

      joined_attributes = proto_record.to_h.keys | (unique_key || [])
      attributes = joined_attributes.map { |attribute_name| [attribute_name, temp_resource.send(attribute_name)] }.to_h

      unique_attrs = attributes.slice(*unique_key)

      record = unique_key_valid?(unique_key, unique_attrs) ?
                 parent.send(plural_model_class).find_or_initialize_by(unique_attrs) :
                 parent.send(plural_model_class).new
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
