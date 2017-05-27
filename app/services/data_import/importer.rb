module DataImport
  class Importer

    def self.import(file_path, source)
      case source
      when :race_result
        import_with(file_path, RaceResult::ReadStrategy, RaceResult::ParseStrategy, RaceResult::TransformStrategy)
      when :csv_efforts
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Efforts::TransformStrategy, model: :effort)
      when :csv_splits
        import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Splits::TransformStrategy, model: :split)
      end
    end

    def import_with(file_path, read_strategy, parse_strategy, transform_strategy, options = {})
      reader = Reader.new(file_path, read_strategy)
      raw_data = reader.read_file
      parser = Parser.new(raw_data, parse_strategy, options)
      parsed_data = parser.attribute_rows
      transformer = Transformer.new(parsed_data, transform_strategy, options)
      records = transformer.records
      persist(records)
    end

    private

    def persist(records)

    end
  end
end
