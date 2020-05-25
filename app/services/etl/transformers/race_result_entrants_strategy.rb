# frozen_string_literal: true

module ETL::Transformers
  class RaceResultEntrantsStrategy < BaseTransformer
    def initialize(parsed_structs, options)
      @proto_records = parsed_structs.map { |struct| ProtoRecord.new(struct) }
      @options = options
      @errors = []
      validate_setup
    end

    def transform
      return if errors.present?

      proto_records.each do |proto_record|
        proto_record.record_type = :effort
        proto_record.map_keys!({name: :full_name, sex: :gender, bib: :bib_number})
        proto_record.normalize_gender!
        remove_name_classifications(proto_record)
        proto_record.split_field!(:full_name, :first_name, :last_name)
        proto_record.slice_permitted!
        proto_record.merge_attributes!(global_attributes)
      end

      # RaceResult sometimes includes no-name runners ("N.n.") who have no gender.
      # We need to filter these out or they will cause the import to fail.
      proto_records.select { |record| record[:gender].present? }
    end

    private

    attr_reader :proto_records

    # Remove commentary like " - LOWLANDER" and " - COURSE RECORD"
    def remove_name_classifications(proto_record)
      proto_record[:full_name] = proto_record[:full_name].sub(/\s-\s[A-Z\s]*/, '')
    end

    def global_attributes
      {event_id: event.id}
    end

    def validate_setup
      errors << missing_event_error unless event.present?
    end
  end
end
