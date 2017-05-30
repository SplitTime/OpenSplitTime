module DataImport
  class Importer

    REPORT_ARRAYS = [:valid_records, :invalid_records, :destroyed_records, :discarded_records, :errors]
    attr_reader *REPORT_ARRAYS

    def initialize(file_path, source, options = {})
      @file_path = file_path
      @source = source
      @options = options
      @valid_records = []
      @invalid_records = []
      @destroyed_records = []
      @discarded_records = []
      @errors = []
    end

    def import
      case source
      when :race_result
        import_with(file_path, RaceResult::ReadStrategy, RaceResult::ParseStrategy, RaceResult::TransformStrategy, options)
      when :csv_efforts
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Efforts::TransformStrategy, options.merge(model: :effort))
      when :csv_splits
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Splits::TransformStrategy, options.merge(model: :split))
      end
    end

    private

    attr_reader :file_path, :source, :options

    def import_with(file_path, read_strategy, parse_strategy, transform_strategy, options)
      reader = DataImport::Reader.new(file_path, read_strategy)
      raw_data = reader.read_file
      self.errors += reader.errors and return if reader.errors.present?

      parser = DataImport::Parser.new(raw_data, parse_strategy, options)
      parsed_structs = parser.parse
      self.errors += parser.errors and return if parser.errors.present?

      transformer = DataImport::Transformer.new(parsed_structs, transform_strategy, options)
      proto_records = transformer.transform
      self.errors += transformer.errors and return if transformer.errors.present?

      proto_record_groups = options[:strict] ? proto_records : proto_records.map { |record| [record] }
      proto_record_groups.each do |proto_record_group|
        loader = DataImport::Loader.new(proto_record_group, options)
        loader.load_records
        REPORT_ARRAYS.each do |group|
          loader.send(group).each { |element| send(group) << element }
        end
      end
    end
  end
end
