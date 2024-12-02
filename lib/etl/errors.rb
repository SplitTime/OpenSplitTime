# frozen_string_literal: true

module ETL
  module Errors
    def bad_url_error(url, error)
      { title: "Bad URL", detail: { messages: ["#{url} reported an error: #{error}"] } }
    end

    def data_not_present_error
      { title: "Data not present", detail: { messages: ["No data was provided"] } }
    end

    def file_not_found_error(file_path)
      { title: "File not found", detail: { messages: ["File #{file_path} could not be read"] } }
    end

    def file_too_large_error(file)
      { title: "File too large", detail: { messages: ["File #{file} is #{file.size / 1.kilobyte} KB, but maximum file size is 500 KB"] } }
    end

    def file_type_incorrect_error(file)
      { title: "File type incorrect", detail: { messages: ["File #{file} must have a .csv extension and must be a CSV file"] } }
    end

    def format_not_recognized_error(format)
      { title: "Format not recognized", detail: { messages: ["data_format #{format} is not recognized"] } }
    end

    def invalid_file_error(file)
      { title: "Invalid file", detail: { messages: ["#{file} is not a valid file"] } }
    end

    def invalid_json_error(string)
      { title: "Invalid JSON", detail: { messages: ["#{string} is not valid JSON"] } }
    end

    def invalid_proto_record_error(proto_record, row_index)
      { title: "Invalid proto record", detail: { row_index: row_index, messages: ["Invalid proto record: #{proto_record}"] } }
    end

    def jsonapi_error_object(record)
      { title: "#{record.class} could not be saved",
        detail: { attributes: record.attributes.compact.transform_keys { |key| key.camelize(:lower) },
                  messages: record.errors.full_messages } }
    end

    def missing_current_user_error
      { title: "Current user id is missing",
        detail: { messages: ["This import requires that a current_user_id be provided"] } }
    end

    def missing_data_error(raw_data)
      { title: "Invalid data",
        detail: { messages: ["The provided file #{raw_data} has a problem with the ['data'] key or its values"] } }
    end

    def missing_event_error
      { title: "Event is missing",
        detail: { messages: ["This import requires that an event be provided"] } }
    end

    def missing_fields_error(raw_data)
      { title: "Invalid fields",
        detail: { messages: ["The provided file #{raw_data} has a problem with the ['list'] key " +
                               "or the ['list']['fields'] key or its values"] } }
    end

    def missing_key_error(*keys)
      { title: "Key is missing",
        detail: { messages: ["This import requires a column titled '#{keys.join(' or ')}' in order to proceed"] } }
    end

    def missing_parent_error(type = nil)
      type ||= "record"
      { title: "Parent is missing",
        detail: { messages: ["This import requires that a parent #{type} be provided"] } }
    end

    def missing_records_error
      { title: "No records were provided",
        detail: { messages: ["No records were provided for this import"] } }
    end

    def missing_split_error
      { title: "Split is missing",
        detail: { messages: ["This import requires that a split be provided"] } }
    end

    def missing_start_key_error
      { title: "Start key is missing",
        detail: { messages: ['This import requires a column titled "start" or "start offset" to indicate at what point split times begin'] } }
    end

    def missing_table_error
      { title: "Table is missing",
        detail: { messages: ["A required table was not found in the provided source data"] } }
    end

    def orders_missing_error(ids)
      { title: "Orders are missing",
        detail: { messages: ["Orders exist in Ultrasignup but are missing in OST: #{ids}"] } }
    end

    def orders_outdated_error(ids)
      { title: "Orders are outdated",
        detail: { messages: ["Orders exist in OST but have been removed from Ultrasignup: #{ids}"] } }
    end

    def resource_not_found_error(resource_class, provided_resource_name, row_index)
      humanized_resource_class = resource_class.to_s.underscore.humanize
      message = provided_resource_name.present? ? "#{humanized_resource_class} could not be found: #{provided_resource_name}" : "#{humanized_resource_class} was not provided"
      { title: "#{humanized_resource_class} not found", detail: { row_index: row_index, messages: [message] } }
    end

    def record_not_saved_error(error, row_index)
      { title: "Record could not be saved",
        detail: { row_index: row_index, messages: ["The record could not be saved: #{error}"] } }
    end

    def resource_error_object(record, row_index)
      { title: "#{record.class} #{record} could not be saved",
        detail: { row_index: row_index, attributes: record.attributes.compact, messages: record.errors.full_messages } }
    end

    def smarter_csv_error(exception)
      { title: "CSV error",
        detail: { messages: [exception.message] } }
    end

    def source_not_recognized_error(source)
      { title: "Source not recognized", detail: { messages: ["Importer does not recognize the source: #{source}"] } }
    end

    def split_mismatch_error(event, time_points_size, time_keys_size)
      { title: "Split mismatch error",
        detail: { messages: ["#{event} expects #{time_points_size} time points (including the start split) " +
                               "but the provided data contemplates #{time_keys_size} time points."] } }
    end

    def transform_failed_error(error_text, row_index)
      { title: "Transform failed error",
        detail: { row_index: row_index, messages: ["Transform failed: #{error_text}"] } }
    end

    def value_not_permitted_error(option, permitted_values, provided_value)
      { title: "Argument value is not permitted",
        detail: { messages: ["Values for #{option} must be within #{permitted_values.to_sentence} but #{provided_value} was provided"] } }
    end
  end
end
