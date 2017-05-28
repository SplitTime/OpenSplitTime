module DataImport
  class Loader
    attr_reader :valid_records, :invalid_records, :destroyed_records, :discarded_records

    def initialize(transformed_structs, options)
      @transformed_structs = transformed_structs
      @options = options
      @valid_records = []
      @invalid_records = []
      @destroyed_records = []
      @discarded_records = []
    end

    def load_records
      ActiveRecord::Base.transaction do
        transformed_structs.each do |struct|
          record = record_from_struct(struct)
          save_discard_or_destroy(record, struct)
          if valid_records.include?(record)
            struct.child_structs.each do |child_struct|
              child_struct["#{struct.record_type}_id"] = record.id
              child_record = record_from_struct(child_struct)
              save_discard_or_destroy(child_record, child_struct)
            end
          end
        end
        raise ActiveRecord::Rollback if invalid_records.present?
      end
    end

    private

    attr_reader :transformed_structs, :options

    def record_from_struct(struct)
      model_class = struct[:record_type].to_s.classify.constantize
      attributes = struct.to_h.except(:record_type, :record_action, :child_structs)
      new_or_existing_record(attributes, model_class)
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

    def save_discard_or_destroy(record, struct)
      if struct.record_action == :destroy
        discard_or_destroy(record)
      else
        save(record)
      end
    end

    def save(record)
      if record.save
        valid_records << record
      else
        invalid_records << record
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
  end
end
