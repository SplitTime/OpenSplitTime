class CsvParser
  BYTE_ORDER_MARK = "\xEF\xBB\xBF".force_encoding('UTF-8')
  attr_reader :errors

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:file_path, :model],
                           exclusive: [:file_path, :model], class: self.class)
    @file_path = args[:file_path]
    @model = args[:model]
    @errors = []
    validate_setup
  end

  def attribute_rows
    @attribute_rows ||= unsafe_rows.map do |attributes|
      {model.to_s.singularize.to_sym => allowed_attributes(attributes)}.with_indifferent_access
    end
  end

  private

  attr_reader :file_path, :model, :global_attributes, :unique_key
  attr_writer :response_status

  def unsafe_rows
    @unsafe_rows ||= SmarterCSV.process(file, key_mapping: params_map, row_sep: :auto, force_utf8: true,
                                                 strip_chars_from_headers: BYTE_ORDER_MARK)
  end

  def allowed_attributes(attributes)
    attributes.slice(*permitted_params)
  end

  def file
    @file ||= FileStore.get(file_path)
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

  def validate_setup
    errors << file_not_found_error unless file.present?
  end

  def file_not_found_error
    {title: 'File not found', detail: {messages: ["File #{file_path} could not be read"]}}
  end
end
