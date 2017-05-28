module DataImport
  class Importer

    def self.import(file_path, source, options = {})
      case source
      when :race_result
        new.import_with(file_path, RaceResult::ReadStrategy, RaceResult::ParseStrategy, RaceResult::TransformStrategy, options)
      when :csv_efforts
        new.import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Efforts::TransformStrategy, options.merge(model: :effort))
      when :csv_splits
        new.import_with(file_path, Csv::ReadStrategy, Csv::ParseStrategy, Csv::Splits::TransformStrategy, options.merge(model: :split))
      end
    end

    def import_with(file_path, read_strategy, parse_strategy, transform_strategy, options)
      reader = DataImport::Reader.new(file_path, read_strategy)
      raw_data = reader.read_file
      return reader.errors if reader.errors.present?
      parser = DataImport::Parser.new(raw_data, parse_strategy, options)
      parsed_data = parser.parse
      return parser.errors if parser.errors.present?
      transformer = DataImport::Transformer.new(parsed_data, transform_strategy, options)
      records = transformer.transform
      return transformer.errors if transformer.errors.present?
      persist(records)
    end

    private

    def persist(records)
      puts records
    end
  end
end
