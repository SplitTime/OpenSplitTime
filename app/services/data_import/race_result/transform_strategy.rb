module DataImport::RaceResult
  class TransformStrategy
    include Transformations

    def initialize(parsed_data, options)
      @parsed_data = parsed_data
      @options = options
    end

    def transform
      map_keys!(:effort)
      normalize_gender!
      split_full_name!
    end

    private

    attr_reader :parsed_data, :options
  end
end
