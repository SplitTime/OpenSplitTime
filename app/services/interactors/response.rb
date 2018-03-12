# frozen_string_literal: true

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

    def message_with_error_report
      "#{message}: #{error_report}"
    end

    def merge(other)
      return self unless other
      combined_errors = errors + other.errors
      combined_message = [message, other.message].join("\n")
      combined_resources = [resources, other.resources].compact.flatten
      Interactors::Response.new(combined_errors, combined_message, combined_resources)
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
