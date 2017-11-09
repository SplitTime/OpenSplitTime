class ProtoRecord
  include DataImport::Transformable

  attr_accessor :record_type, :record_action
  attr_reader :children, :attributes

  def initialize(args = {})
    @record_type = args[:record_type]&.to_sym
    @record_action = args[:record_action]&.to_sym
    @children = Array.wrap(args[:children]) || []
    @attributes = OpenStruct.new(args.to_h.except(nil, :record_type, :record_action, :children))
    validate_setup
  end

  delegate :[], :[]=, :to_h, :delete_field, to: :attributes

  def record_class
    record_type&.to_s&.classify&.constantize
  end

  def params_class
    record_class && "#{record_class}Parameters".constantize
  end

  def resource_attributes(attribute_names = [])
    resource = record_class.new(to_h)
    joined_attributes = to_h.keys | (attribute_names || [])
    joined_attributes.map { |attribute_name| [attribute_name, resource.send(attribute_name)] }.to_h
  end

  private

  def validate_setup
    raise ArgumentError, 'children of a ProtoRecord must be ProtoRecords' unless children.all? { |child| child.is_a?(ProtoRecord) }
  end
end
