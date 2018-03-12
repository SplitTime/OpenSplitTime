# frozen_string_literal: true

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
      return nil if proto_record.record_action == :destroy
      model_class = proto_record.record_class
      attributes = proto_record.to_h
      record = model_class.new(attributes)
      assign_child_records(proto_record, record)
      add_audit_attributes(record)
      record
    end

    def assign_child_records(proto_record, record)
      proto_record.children.each do |child|
        unless child.record_action == :destroy
          child_record = record.send(child.record_type.to_s.pluralize).new
          child_record.assign_attributes(child.to_h)
        end
      end
    end
  end
end
