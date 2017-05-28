module DataImport
  class Importer

    def self.import(file_path, source, options = {})
      case source
      when :race_result
        import_with(file_path, RaceResult::ReadStrategy, RaceResult::ParseStrategy, RaceResult::TransformStrategy, options)
      when :csv_efforts
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Efforts::TransformStrategy, options.merge(model: :effort))
      when :csv_splits
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Splits::TransformStrategy, options.merge(model: :split))
      end
    end

    def self.import_with(file_path, read_strategy, parse_strategy, transform_strategy, options)
      reader = DataImport::Reader.new(file_path, read_strategy)
      raw_data = reader.read_file
      return reader.errors if reader.errors.present?

      parser = DataImport::Parser.new(raw_data, parse_strategy, options)
      parsed_structs = parser.parse
      return parser.errors if parser.errors.present?

      transformer = DataImport::Transformer.new(parsed_structs, transform_strategy, options)
      proto_records = transformer.transform
      return transformer.errors if transformer.errors.present?

      proto_record_groups = options[:strict] ? proto_records : proto_records.map { |record| [record] }
      proto_record_groups.each do |proto_record_group|
        loader = DataImport::Loader.new(proto_record_group, options)
        loader.load_records
      end
    end
  end
end
