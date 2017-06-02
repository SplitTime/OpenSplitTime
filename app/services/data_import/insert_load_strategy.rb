module DataImport
  class InsertLoadStrategy
    include DataImport::Errors
    attr_reader :saved_records, :invalid_records, :ignored_records, :errors

    def initialize(proto_records, options)
      @proto_records = proto_records
      @options = options
      @saved_records = []
      @invalid_records = []
      @ignored_records = []
      @errors = []
      validate_setup
    end

    def load_records
      return if errors.present?
      ActiveRecord::Base.transaction do

        proto_records.each do |proto_record|
          record = record_from_proto(proto_record)

          if record.save
            child_records = proto_record.children.map { |child_proto_record| record_from_proto(child_proto_record) }.compact
            assign_child_records(record, child_records)

            if child_records.all?(&:persisted?)
              saved_records << record
            else
              invalid_records << record
            end
          else
            invalid_records << record
          end

        end
        raise ActiveRecord::Rollback if invalid_records.present?
      end
    end

    private

    attr_reader :proto_records, :options

    def record_from_proto(proto_record)
      record = fetch_record(proto_record)
      record.created_by = current_user_id if record.new_record?
      record.updated_by = current_user_id
      eliminate(record) and return nil if proto_record.record_action == :destroy
      record
    end

    def eliminate(record)
      ignored_records << record
    end

    def fetch_record(proto_record)
      model_class = proto_record.record_class
      attributes = proto_record.to_h
      model_class.new(attributes)
    end

    def assign_child_records(record, child_records)
      child_records.each { |child_record| record.send(child_record.model_name.plural) << child_record }
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
