class CsvImporter
  attr_reader :saved_records, :errors, :response_status

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:file_path, :model],
                           exclusive: [:file_path, :model, :global_attributes],
                           class: self.class)
    @file_path = args[:file_path]
    @model = args[:model]
    @global_attributes = args[:global_attributes] || {}
    @saved_records = []
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
          saved_records << record
        else
          errors << [record.attributes.compact, record.errors.full_messages]
          self.response_status = :unprocessable_entity
        end
      end
      raise ActiveRecord::Rollback if response_status
    end
    self.response_status ||= :created
  end

  private

  attr_reader :file_path, :model, :global_attributes
  attr_writer :response_status

  def records
    @records ||= processed_attributes.map { |attributes| klass.new(global_attributes.merge(attributes)) }
  end

  def processed_attributes
    @processed_attributes ||= SmarterCSV.process(file, key_mapping: key_mapping, row_sep: :auto)
  end

  def file
    @file ||= FileStore.read(file_path)
  end

  def key_mapping
    params_class.key_mapping
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
  end
end
