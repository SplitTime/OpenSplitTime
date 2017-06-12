class ProtoRecord
  include DataImport::Transformable

  attr_accessor :record_type, :record_action
  attr_reader :children, :attributes

  def initialize(args = {})
    @record_type = args[:record_type]&.to_sym
    @record_action = args[:record_action]&.to_sym
    @children = Array.wrap(args[:children]) || []
    @attributes = OpenStruct.new(args.to_h.except(:record_type, :record_action, :children))
    validate_setup
  end

  delegate :[], :[]=, :to_h, :delete_field, to: :attributes

  def record_class
    record_type&.to_s&.classify&.constantize
  end

  def params_class
    record_class && "#{record_class}Parameters".constantize
  end

  private

  def validate_setup
    raise ArgumentError, 'children of a ProtoRecord must be of type ProtoRecord' unless children.all? { |child| child.is_a?(ProtoRecord) }
  end
end
