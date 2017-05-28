class ProtoRecord
  attr_reader :attributes, :children
  attr_accessor :record_type, :record_action

  def initialize(args = {})
    ArgsValidator.validate(params: args, exclusive: [:record_type, :record_action, :attributes, :children],
                           class: self.class)
    @record_type = args[:record_type]&.to_sym
    @record_action = args[:record_action]&.to_sym
    @attributes = OpenStruct.new(args[:attributes])
    @children = Array.wrap(args[:children]) || []
    validate_setup
  end

  def [](method)
    send(method)
  end

  def []=(method, value)
    send("#{method}=", value)
  end

  private

  def validate_setup
    raise ArgumentError, 'children of a ProtoRecord must be of type ProtoRecord' unless
        children.all? { |child| child.is_a?(ProtoRecord) }
  end

  def method_missing(method, value = nil)
    if /^(\w+)=$/ =~ method
      attributes["#{$1}"] = value
    end
    attributes[method]
  end
end
