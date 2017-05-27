class RecordBuilder
  attr_reader :valid_records, :invalid_records, :errors

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :attribute_rows,
                           exclusive: [:attribute_rows, :global_attributes, :unique_key],
                           class: self.class)
    @attribute_rows = args[:attribute_rows]
    @model = args[:model]
    @global_attributes = args[:global_attributes] || {}
    @unique_key = Array.wrap(args[:unique_key]) || []
    @valid_records = []
    @invalid_records = []
    @errors = []
    validate_setup
  end

  def records
    @records ||= attribute_rows.map do |row|
      # Assigning to a temp_record allows the model to assign virtual attributes to real attributes
      # For example, effort.event = event results in effort.event_id == event.id
      temp_record = klass.new(row_with_global(row))
      updated_attributes = temp_record.attributes.compact.with_indifferent_access
      record = new_or_existing_record(updated_attributes)
      record.assign_attributes(updated_attributes)
      record
    end
  end

  private

  attr_reader :attribute_rows, :model, :global_attributes, :unique_key
  attr_writer :response_status

  def new_or_existing_record(updated_attributes)
    unique_key_pairs = unique_key_pairs(updated_attributes)
    (unique_key.present? && unique_key_pairs.values.all?(&:present?)) ?
        klass.find_or_initialize_by(unique_key_pairs) :
        klass.new
  end

  def unique_key_pairs(attributes)
    unique_key.map { |field_name| [field_name, attributes[field_name]] }.to_h
  end

  def row_with_global(row)
    global_attributes.merge(row.to_h)
  end

  def permitted_params
    params_class.permitted
  end

  def params_class
    @params_class ||= "#{klass}Parameters".constantize
  end

  def klass
    @klass ||= model.to_s.classify.constantize
  end

  def validate_setup
    errors << "Unique key #{unique_key} is not allowed" if unique_key.present? &&
        unique_key.any? { |field_name| permitted_params.exclude?(field_name) }
  end
end
