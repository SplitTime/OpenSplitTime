# frozen_string_literal: true

class ProtoRecord
  include ETL::Transformable

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

  def parent_child_attributes
    to_h.merge(child_attributes)
  end

  def resource_attributes(attribute_names = [])
    resource = record_class.new(to_h)
    joined_attributes = to_h.keys | (attribute_names || [])
    joined_attributes.map { |attribute_name| [attribute_name, resource.send(attribute_name)] }.to_h
  end

  def transform_as(model, options = {})
    self.record_type = model
    underscore_keys!
    map_keys!(params_class.mapping)
    run_specific_transforms(model, options)
  end

  private

  def run_specific_transforms(model, options)
    event = options[:event]

    case model
      when :effort
        normalize_gender!
        normalize_country_code!
        normalize_state_code!
        create_country_from_state!
        normalize_date!(:birthdate)
        normalize_datetime!(:start_time)
        set_offset_from_start_time!(event)
        self[:event_id] = event.id

      when :split
        convert_split_distance!
        align_split_distance!(event.ordered_splits.map(&:distance_from_start))
        self[:course_id] = event.course_id

      else
        return
    end
  end

  def child_attributes
    children.group_by(&:record_type).map { |record_type, proto_records| ["#{record_type.to_s.pluralize}_attributes", proto_records.map(&:to_h)] }.to_h
  end

  def validate_setup
    raise ArgumentError, 'children of a ProtoRecord must be ProtoRecords' unless children.all? { |child| child.is_a?(ProtoRecord) }
  end
end
