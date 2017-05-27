module DataImport::Csv::Splits
  class TransformStrategy

    def initialize(parsed_data)
      @parsed_data = parsed_data
    end

    def transform
      parsed_data
    end

    private

    attr_reader :parsed_data
  end
end
