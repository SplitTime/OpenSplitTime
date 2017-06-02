module DataImport
  class Importer
    include DataImport::Errors

    REPORT_ARRAYS = [:saved_records, :invalid_records, :destroyed_records, :ignored_records, :errors]
    attr_reader *REPORT_ARRAYS

    def initialize(file_path, format, options = {})
      @file_path = file_path
      @format = format
      @options = options
      @saved_records = []
      @invalid_records = []
      @destroyed_records = []
      @ignored_records = []
      @errors = []
    end

    def import
      case format
      when :race_result_full
        import_with(file_path, RaceResult::ReadStrategy, RaceResult::ParseStrategy, RaceResult::TransformStrategy, Loaders::InsertStrategy, options)
      when :race_result_times
        import_with(file_path, RaceResult::ReadStrategy, RaceResult::ParseStrategy, RaceResult::TransformStrategy, Loaders::SplitTimeUpsertStrategy, options)
      when :csv_efforts
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::TransformEffortsStrategy, Loaders::UpsertStrategy, options)
      when :csv_splits
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::TransformSplitsStrategy, Loaders::UpsertStrategy, options)
      else
        self.errors << format_not_recognized_error(format)
      end
    end

    private

    attr_reader :file_path, :format, :options
    attr_writer *REPORT_ARRAYS

    def import_with(file_path, read_strategy, parse_strategy, transform_strategy, load_strategy, options)
      reader = DataImport::Reader.new(file_path, read_strategy)
      raw_data = reader.read_file
      self.errors += reader.errors and return if reader.errors.present?

      parser = DataImport::Parser.new(raw_data, parse_strategy, options)
      parsed_structs = parser.parse
      self.errors += parser.errors and return if parser.errors.present?

      transformer = DataImport::Transformer.new(parsed_structs, transform_strategy, options)
      proto_records = transformer.transform
      self.errors += transformer.errors and return if transformer.errors.present?

      proto_record_groups = options[:strict] ? [proto_records] : proto_records.map { |record| [record] }
      proto_record_groups.each do |proto_record_group|
        loader = DataImport::Loader.new(proto_record_group, load_strategy, options)
        loader.load_records
        REPORT_ARRAYS.each do |report_array|
          loader.send(report_array).each { |report_element| send(report_array) << report_element }
        end
      end
    end
  end
end
