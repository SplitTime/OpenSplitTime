module ETL::Extractors
  class HTMLPageStrategy
    include ETL::Errors
    attr_reader :errors

    def initialize(url, options)
      @url = url
      @options = options
      @errors = []
    end

    def extract
      Nokogiri::HTML(open(url))
    rescue => e
      (errors << bad_url_error(url, e)) and return nil
    end

    private

    attr_reader :url, :options
  end
end
