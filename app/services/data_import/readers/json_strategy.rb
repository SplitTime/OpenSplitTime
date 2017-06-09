module DataImport::Readers
  class JsonStrategy
    include DataImport::Errors
    attr_reader :errors

    def initialize(data_object)
      @data_object = data_object
      @errors = []
    end

    def read_file
      if data_object
        puts "#{data_object.class} size: #{data_object.size}"
        puts data_object
        JSON.parse(data_object)
      else
        errors << data_not_present_error
        nil
      end
    end

    private

    attr_reader :data_object
  end
end
