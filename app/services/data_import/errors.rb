module DataImport
  module Errors

    def data_not_present_error
      {title: 'Data not present', detail: {messages: ['No data was provided']}}
    end

    def file_not_found_error(file_path)
      {title: 'File not found', detail: {messages: ["File #{file_path} could not be read"]}}
    end

    def format_not_recognized_error(format)
      {title: 'Format not recognized', detail: {messages: ["data_format #{format} is not recognized"]}}
    end

    def invalid_proto_record_error(proto_record)
      {title: 'Invalid proto record', detail: {messages: ["#{proto_record} is invalid"]}}
    end

    def jsonapi_error_object(record)
      {title: "#{record.class} could not be saved",
       detail: {attributes: record.attributes.compact, messages: record.errors.full_messages}}
    end

    def missing_current_user_error
      {title: 'Current user id is missing',
       detail: {messages: ['This import requires that a current_user_id be provided']}}
    end

    def missing_data_error(raw_data)
      {title: 'Invalid data',
       detail: {messages: ["The provided file #{raw_data} has a problem with the ['data'] key or its values"]}}
    end

    def missing_event_error
      {title: 'Event is missing',
       detail: {messages: ['This import requires that an event be provided']}}
    end

    def missing_fields_error(raw_data)
      {title: 'Invalid fields',
       detail: {messages: ["The provided file #{raw_data} has a problem with the ['list'] key " +
                               "or the ['list']['fields'] key or its values"]}}
    end

    def source_not_recognized_error(source)
      {title: 'Source not recognized', detail: {messages: ["Importer does not recognize the source: #{source}"]}}
    end

    def split_mismatch_error(event, time_points, time_keys)
      {title: 'Split mismatch error',
       detail: {messages: ["#{event} expects #{time_points.size - 1} time points (excluding the start split) " +
                               "but the json response contemplates #{time_keys.size} time points."]}}
    end
  end
end
