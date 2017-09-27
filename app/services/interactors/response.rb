module Interactors
  Response = Struct.new(:errors, :message) do
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
      errors.map { |error| "\n#{error[:title]}: #{error[:detail]}" }.join
    end
  end
end
