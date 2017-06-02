module DataImport::RaceResult
  class ReadStrategy
    include DataImport::Errors
    attr_reader :errors

    def initialize(data_object)
      @data_object = data_object
      @errors = []
    end

    def read_file
      case
      when data_object.is_a?(Hash)
        data_object
      when data_object.is_a?(StringIO)
        JSON.parse(File.read(data_object))
      else # Assume a real file path
        if file
          JSON.parse(File.read(file))
        else
          errors << file_not_found_error(data_object)
          nil
        end
      end
    end

    private

    attr_reader :data_object

    def file
      @file ||= FileStore.get(data_object)
    end
  end
end
