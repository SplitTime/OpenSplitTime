# frozen_string_literal: true

class CsvBuilder
  def initialize(model_class, resources)
    @model_class = model_class
    @resources = resources || []
  end

  def full_string
    return error_message if error_message.present?

    CSV.generate do |csv|
      csv << headers
      resources.each { |resource| csv << serialize_resource(resource) }
    end
  end

  def model_class_name
    @model_class_name ||= model_class&.name&.underscore&.pluralize
  end

  private

  attr_reader :model_class, :resources

  def serialize_resource(resource)
    export_attributes.map do |attribute|
      value = resource.send(attribute)
      value.is_a?(Array) ? value.join(' ') : value
    end
  end

  def headers
    export_attributes.map(&:humanize)
  end

  def export_attributes
    @export_attributes ||= params_class.csv_attributes
  end

  def params_class
    @params_class ||= "#{model_class}Parameters".constantize
  end

  def error_message
    return 'No model class was provided' unless model_class.present?
    "No csv attributes defined for #{model_class}" unless export_attributes.present?
  end
end
