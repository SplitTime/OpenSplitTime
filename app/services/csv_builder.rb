class CsvBuilder

  attr_reader :resources

  def initialize(resources)
    @resources = resources || []
  end

  def headers
    resources.present? ?
        (export_attributes.map(&:humanize).presence || ["No csv attributes defined for #{model_class}"]) :
        ['No resources were provided for export']
  end

  def export_attributes
    params_class.csv_attributes
  end

  def model_class_name
    model_class.name.underscore.pluralize
  end

  private

  attr_reader :model, :params

  def model_class
    resources.first&.class
  end

  def params_class
    model_class ? "#{model_class}Parameters".constantize : BaseParameters
  end
end
