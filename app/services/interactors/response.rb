module Interactors
  Response = Struct.new(:errors, :message, :resources) do
    def successful?
      errors.blank?
    end

    def error_report
      case errors.size
      when 0
        "No errors were reported"
      when 1
        "1 error was reported:#{error_details}"
      else
        "#{errors.size} errors were reported:#{error_details}"
      end
    end

    private

    def error_details
      errors.map { |error| "\n#{error[:title]}: #{error_messages(error[:detail])}" }.join
    end

    def error_messages(error_detail)
      error_detail[:message] || error_detail[:messages]&.join || error_detail
    end
  end
end
