module DataImport::Readers
  class JsonFileStrategy
    include DataImport::Errors
    attr_reader :errors

    def initialize(file_path)
      @file_path = file_path
      @errors = []
    end

    def read_file
      if file
        JSON.parse(File.read(file))
      else
        errors << file_not_found_error(file_path)
        nil
      end
    end

    private

    attr_reader :file_path

    def file
      @file ||= FileStore.get(file_path)
    end
  end
end
