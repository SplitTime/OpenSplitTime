module DataImport::Loaders
  class InsertStrategy < BaseLoader

    def post_initialize(options)
    end

    def custom_load
      proto_records.each do |proto_record|
        record = build_record(proto_record)

        if record.save
          child_records = proto_record.children.map { |child_proto_record| build_record(child_proto_record) }.compact
          assign_child_records(record, child_records)

          if child_records.all?(&:persisted?)
            saved_records << record
          else
            record.validate # Adds child_record errors to record
            invalid_records << record
          end
        else
          invalid_records << record
        end
      end
    end

    private

    def build_record(proto_record)
      model_class = proto_record.record_class
      attributes = proto_record.to_h
      record = model_class.new(attributes)
      add_audit_attributes(record)
      return nil if proto_record.record_action == :destroy
      record
    end

    def eliminate(record)
      ignored_records << record
    end

    def assign_child_records(record, child_records)
      child_records.each { |child_record| record.send(child_record.model_name.plural) << child_record }
    end
  end
end
