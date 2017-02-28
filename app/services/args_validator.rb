class ArgsValidator
  class << self
    attr_accessor :console_notifications

    def validate(args)
      new(args).validate
    end

    def exclusive
      [:params, :required, :required_alternatives, :exclusive, :deprecated, :class]
    end
  end

  def initialize(args)
    @params = args[:params]
    @required = Array.wrap(args[:required]) || []
    @required_alternatives = Array.wrap(args[:required_alternatives]) || []
    @exclusive = Array.wrap(args[:exclusive]) || []
    @deprecated = Array.wrap(args[:deprecated])
    @klass = args[:class]
    @args = args
    validate_setup(args)
    # Set ArgsValidator.console_notifications to true or false
    # in /config/initializers/args_validator.rb
  end

  def validate
    report_deprecations
    validate_hash
    validate_required_params
    validate_required_alternatives
    validate_exclusive_params
    notify_console(args) if self.class.console_notifications
  end

  private

  attr_reader :params, :required, :required_alternatives, :exclusive, :deprecated, :klass, :args

  def report_deprecations
    deprecated.each do |deprecation_pair|
      deprecation_pair.each do |deprecated_arg, replacement_arg|
        warn "use of '#{deprecated_arg}' #{for_klass}has been deprecated in favor of '#{replacement_arg}'" if params[deprecated_arg]
      end
    end
  end

  def validate_hash
    raise ArgumentError, "arguments #{for_klass}must be provided as a hash" unless params.is_a?(Hash)
  end

  def validate_required_params
    required.each do |required_arg|
      raise ArgumentError, "arguments #{for_klass}must include #{required_arg}" if params[required_arg].nil?
    end
  end

  def validate_required_alternatives
    if required_alternatives.present?
      required_groups = required_alternatives.map { |alternative| Array.wrap(alternative) }
      unless required_groups.any? { |group| group.none? { |arg| params[arg].nil? } }
        raise ArgumentError, "arguments #{for_klass}must include one of " +
            "#{required_groups.map(&:to_sentence)
                   .to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')}"
      end
    end
  end

  def validate_exclusive_params
    if exclusive.present?
      params.each_key do |arg_name|
        raise ArgumentError, "arguments #{for_klass}may not include #{arg_name}" unless exclusive.include?(arg_name)
      end
    end
  end

  def for_klass
    klass && "for #{klass} "
  end

  def validate_setup(args)
    raise ArgumentError, 'no arguments provided for validation' unless params
    args.each_key do |arg_name|
      raise ArgumentError, "arguments for ArgsValidator may not include #{arg_name}" unless ArgsValidator.exclusive.include?(arg_name)
    end
  end

  def notify_console(args)
    puts ColorizeText.green("ArgsValidator validated arguments for #{klass || 'an unspecified class'}")
    puts args[:params].transform_values { |value| value.respond_to?(:map) ?
        value.map { |object| object.try(:name) || object.try(:id) || object.to_s } :
        value.try(:name) || value.try(:id) || value.to_s }
  end
end