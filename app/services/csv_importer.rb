class CsvImporter
  def self.import(args)
    importer = new(args)
    importer.report
  end

  attr_reader :saved_records, :rejected_records

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:file_path, :model],
                           exclusive: [:file_path, :model, :global_attributes],
                           class: self.class)
    @file_path = args[:file_path]
    @model = args[:model]
    @global_attributes = args[:global_attributes] || {}
    @saved_records = []
    @rejected_records = []
  end

  def import
    records.each do |record|
      if record.save
        saved_records << record
      else
        rejected_records << record
      end
    end
  end

  def report
    "Imported #{saved_records.size} #{humanized_class}" +
        "and rejected #{rejected_records.size} #{humanized_class}"
  end

  # private

  attr_reader :file_path, :model, :global_attributes

  def records
    @records ||= processed_attributes.map { |attributes| klass.new(attributes.merge(global_attributes)) }
  end

  def processed_attributes
    @processed_attributes ||= SmarterCSV.process(file_path)
  end

  def klass
    @klass ||= model.to_s.classify.constantize
  end

  def humanized_class
    model.to_s.humanize(capitalize: false)
  end
end
