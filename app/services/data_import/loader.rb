module DataImport
  class Loader
    include DataImport::Errors
    attr_reader :valid_records, :invalid_records, :destroyed_records, :discarded_records, :errors

    def initialize(proto_records, options)
      @proto_records = proto_records
      @options = options
      @valid_records = []
      @invalid_records = []
      @destroyed_records = []
      @discarded_records = []
      @errors = []
      validate_setup
    end

    def load_records
      return if errors.present?
      ActiveRecord::Base.transaction do

        proto_records.each do |proto_record|
          record = record_from_proto(proto_record)
          save_discard_or_destroy(record, proto_record)

          if valid_records.include?(record)
            proto_record.children.each do |child_proto_record|
              child_proto_record["#{proto_record.record_type}_id"] = record.id
              child_record = record_from_proto(child_proto_record)
              save_discard_or_destroy(child_record, child_proto_record)
            end
          end
        end

        raise ActiveRecord::Rollback if invalid_records.present?
      end
      invalid_records.present? ? errors : valid_records
    end

    private

    attr_reader :proto_records, :options

    def record_from_proto(proto_record)
      model_class = proto_record.record_class
      attributes = proto_record.to_h
      record = new_or_existing_record(attributes, model_class)
      audit_attributes = record.new_record? ? [:created_by, :updated_by] : [:updated_by]
      audit_attributes.each { |attribute| record.assign_attributes(attribute => current_user_id) }
      record
    end

    def new_or_existing_record(attributes, model_class)
      unique_key = params_class(model_class).unique_key
      unique_attributes = attributes.slice(*unique_key)
      record = (unique_key_valid?(unique_key, unique_attributes)) ?
                   model_class.find_or_initialize_by(unique_attributes) :
                   model_class.new
      record.assign_attributes(attributes)
      record
    end

    def unique_key_valid?(unique_key, unique_attributes)
      unique_key.present? && unique_key.size == unique_attributes.size && unique_attributes.values.all?(&:present?)
    end

    def save_discard_or_destroy(record, proto_record)
      if proto_record.record_action == :destroy
        discard_or_destroy(record)
      else
        attempt_to_save(record)
      end
    end

    def attempt_to_save(record)
      if record.changed? && !record.save
        invalid_records << record
        errors << jsonapi_error_object(record)
      else
        valid_records << record
      end
    end

    def discard_or_destroy(record)
      if record.new_record?
        discarded_records << record
      else
        begin
          destroyed_records << record if record.destroy
        rescue ActiveRecord::ActiveRecordError => exception
          record.errors.add(exception)
          invalid_records << record
        end
      end
    end

    def params_class(model_name)
      "#{model_name.to_s.classify}Parameters".constantize
    end

    def current_user_id
      options[:current_user_id]
    end

    def validate_setup
      errors << missing_current_user_error unless current_user_id
      proto_records.each do |proto_record|
        errors << invalid_proto_record_error(proto_record) unless proto_record.record_class
      end
    end
  end
end
