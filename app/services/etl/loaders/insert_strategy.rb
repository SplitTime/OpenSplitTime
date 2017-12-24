module ETL::Loaders
  class InsertStrategy < BaseLoader

    def post_initialize(options)
    end

    def custom_load
      proto_records.each do |proto_record|
        record = build_record(proto_record)

        if record.save
          saved_records << record
        else
          invalid_records << record
        end
      end
    end

    private

    def build_record(proto_record)
      model_class = proto_record.record_class
      attributes = proto_record.parent_child_attributes
      record = model_class.new(attributes)
      add_audit_attributes(record)
      return nil if proto_record.record_action == :destroy
      record
    end
  end
end
