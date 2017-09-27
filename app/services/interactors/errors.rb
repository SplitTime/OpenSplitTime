module Interactors
  module Errors
    def resource_error_object(record)
      {title: "#{record.class} could not be saved",
       detail: {attributes: record.attributes.compact, messages: record.errors.full_messages}}
    end
  end
end
