class ProtoRecord
  include DataImport::Transformable

  attr_accessor :record_type, :record_action
  attr_reader :children, :attributes

  def initialize(args = {})
    @record_type = args[:record_type]&.to_sym
    @record_action = args[:record_action]&.to_sym
    @children = Array.wrap(args[:children]) || []
    @attributes = OpenStruct.new(args.except(:record_type, :record_action, :children))
    validate_setup
  end

  delegate :[], :[]=, :to_h, :delete_field, to: :attributes

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
