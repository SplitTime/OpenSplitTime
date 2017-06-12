module DataImport::Readers
  class JsonStrategy
    include DataImport::Errors
    attr_reader :errors

    def initialize(json_blob)
      @json_blob = json_blob
      @errors = []
    end

    def read_file
      if json_blob.present?
        begin
          JSON.parse(json_blob)
        rescue JSON::ParserError
          (errors << invalid_json_error(json_blob)) and return nil
        end
      else
        (errors << data_not_present_error) and return nil
      end
    end

    private

    attr_reader :json_blob
  end
end
