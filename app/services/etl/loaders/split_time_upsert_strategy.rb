# frozen_string_literal: true

module ETL::Loaders
  class SplitTimeUpsertStrategy < BaseLoader

    def post_initialize(options)
      @parent_model = Effort
      @child_model = SplitTime
      @parent_key = [:event_id, :bib_number]
      @child_key = [:lap, :split_id, :sub_split_bitkey]
    end

    def custom_load
      proto_records.each do |proto_record|
        parent_record = fetch_parent(proto_record)
        child_records = proto_record.children.map { |child_proto_record| child_record_from_proto(child_proto_record, parent_record) }.compact

        child_records.each do |child_record|
          if parent_record.persisted? && (child_record.new_record? || child_record.changed?)
            upsert(child_record, parent_record)
          else
            ignored_records << child_record
          end
        end
      end
    end

    private

    attr_reader :parent_model, :child_model, :parent_key, :child_key

    def fetch_parent(proto_record)
      fetch_record(proto_record, parent_model, parent_key, parent_model)
    end

    def fetch_child(proto_record, parent_record)
      child_scope = parent_record&.send(child_model.model_name.plural) || child_model.none
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
      # if record.new_record?
        ignored_records << record
      # else
      #   begin
      #     destroyed_records << record if record.destroy
      #   rescue ActiveRecord::ActiveRecordError => exception
      #     record.errors.add(exception)
      #     invalid_records << record
      #   end
      # end
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
  end
end
