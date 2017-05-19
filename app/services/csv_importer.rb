class CsvImporter
  BYTE_ORDER_MARK = "\xEF\xBB\xBF".force_encoding('UTF-8')
  attr_reader :valid_records, :invalid_records, :errors, :response_status

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:file_path, :model],
                           exclusive: [:file_path, :model, :global_attributes, :unique_key],
                           class: self.class)
    @file_path = args[:file_path]
    @model = args[:model]
    @global_attributes = args[:global_attributes] || {}
    @unique_key = args[:unique_key]
    @valid_records = []
    @invalid_records = []
    @errors = []
    validate_setup
  end

  def import
    if errors.present?
      self.response_status = :unprocessable_entity
      return
    end
    ActiveRecord::Base.transaction do
      records.each do |record|
        if record.save
          valid_records << record
        else
          invalid_records << record
          self.response_status = :unprocessable_entity
        end
      end
      raise ActiveRecord::Rollback if response_status
    end
    self.response_status ||= :created
  end

  private

  attr_reader :file_path, :model, :global_attributes, :unique_key
  attr_writer :response_status

  def records
    @records ||= processed_attributes.map do |attributes|
      record = unique_key.present? ? klass.find_or_initialize_by(unique_key => attributes[unique_key]) : klass.new
      record.assign_attributes(allowed_attributes(attributes))
      record
    end
  end

  def processed_attributes
    @processed_attributes ||= SmarterCSV.process(file, key_mapping: params_map, row_sep: :auto, force_utf8: true,
                                                 strip_chars_from_headers: BYTE_ORDER_MARK)
  end

  def allowed_attributes(attributes)
    global_attributes.merge(attributes.slice(*permitted_params))
  end

  def file
    @file ||= FileStore.read(file_path)
  end

  def params_map
    params_class.mapping
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

  def humanized_class
    model.to_s.humanize(capitalize: false)
  end

  def validate_setup
    errors << "File #{file_path} could not be read" unless file.present?
    errors << "Unique key #{unique_key} is not allowed" if unique_key.present? && permitted_params.exclude?(unique_key)
  end
end
