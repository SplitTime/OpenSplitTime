class CsvPresenter < BasePresenter

  attr_reader :resources

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:model, :params], exclusive: [:model, :params], class: self.class)
    @model = args[:model]
    @params = args[:params]
    @resources = model_class.where(filter_hash).order(sort_hash)
  end

  def headers
    attributes.map(&:humanize)
  end

  def attributes
    params_class.csv_attributes
  end

  private

  attr_reader :model, :params

  def params_class
    "#{model_class}Parameters".constantize
  end

  def model_class
    model.classify.constantize
  end
end
