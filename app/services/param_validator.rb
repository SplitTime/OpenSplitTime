class ParamValidator
  def self.validate(args)
    new(args).validate
  end

  def initialize(args)
    @params = args[:params]
    @required = args[:required] || []
    @required_alternatives = args[:required_alternatives] || []
    @klass = args[:class]
    raise ArgumentError, 'no parameters provided for validation' unless params
  end

  def validate
    validate_hash
    validate_required_params
    validate_required_alternatives
  end

  private

  attr_reader :params, :required, :required_alternatives, :klass

  def validate_hash
    raise ArgumentError, "parameters #{for_klass}must be provided as a hash" unless params.is_a?(Hash)
  end

  def validate_required_params
    raise ArgumentError, "parameters #{for_klass}must include all of #{required.to_sentence}" unless
        required.all? { |arg| params[arg] }
  end

  def validate_required_alternatives
    if required_alternatives.present?
      raise ArgumentError, "parameters #{for_klass}must include one of #{required_alternatives.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')}" unless
          required_alternatives.any? { |arg| params[arg] }
    end
  end

  def for_klass
    klass && "for #{klass} "
  end
end