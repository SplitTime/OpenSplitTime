module DataImport
  class SplitTimeUpsertLoadStrategy
    include DataImport::Errors
    attr_reader :saved_records, :invalid_records, :destroyed_records, :ignored_records, :errors

    def initialize(proto_records, options)
      @proto_records = proto_records
      @options = options
      @parent_model = Effort
      @child_model = SplitTime
      @parent_key = [:event_id, :bib_number]
      @child_key = [:lap, :split_id, :sub_split_bitkey]
      @saved_records = []
      @invalid_records = []
      @destroyed_records = []
      @ignored_records = []
      @errors = []
      validate_setup
    end

    def load_records
      return if errors.present?
      ActiveRecord::Base.transaction do

        proto_records.each do |proto_record|
          parent_record = fetch_parent(proto_record)
          child_records = proto_record.children.map { |child_proto_record| child_record_from_proto(child_proto_record, parent_record) }.compact

          child_records.each do |child_record|
            if parent_record.persisted? && (child_record.new_record? || child_record.changed?)
              upsert(child_record, parent_record)
            else
              child_record.errors.add(:base, "no matching parent was found for #{parent_record.model_name} having attributes #{parent_record.attributes}")
              ignored_records << child_record
            end
          end
        end

        raise ActiveRecord::Rollback if invalid_records.present?
      end
    end

    private

    attr_reader :proto_records, :options, :parent_model, :child_model, :parent_key, :child_key

    def fetch_parent(proto_record)
      fetch_record(proto_record, parent_model, parent_key, parent_model)
    end

    def fetch_child(proto_record, parent_record)
      child_scope = parent_record ? parent_record.send(child_model.model_name.plural) : child_model.send(:none)
      fetch_record(proto_record, child_model, child_key, child_scope)
    end

    def fetch_record(proto_record, model_class, unique_key, scope)
      attributes = proto_record.to_h
      unique_attributes = attributes.slice(*unique_key)
      record = unique_key_valid?(unique_key, unique_attributes) ?
                   scope.find_or_initialize_by(unique_attributes) :
                   model_class.new
      record.assign_attributes(attributes)
      record
    end

    def unique_key_valid?(unique_key, unique_attributes)
      unique_key.present? && unique_key.size == unique_attributes.size && unique_attributes.values.all?(&:present?)
    end

    def child_record_from_proto(proto_record, parent_record)
      record = fetch_child(proto_record, parent_record)
      eliminate(record) and return nil if proto_record.record_action == :destroy
      record
    end

    def eliminate(record)
      if record.new_record?
        record.errors.add(:base, 'the transformer marked this record for elimination')
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

    def upsert(child_record, parent_record)
      add_audit_attributes(child_record)
      save_result = child_record.new_record? ?
                        parent_record.send(child_record.model_name.plural) << child_record :
                        child_record.save
      if save_result
        saved_records << child_record
      else
        invalid_records << child_record
      end
    end

    def add_audit_attributes(record)
      record.created_by = current_user_id if record.new_record?
      record.updated_by = current_user_id
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
