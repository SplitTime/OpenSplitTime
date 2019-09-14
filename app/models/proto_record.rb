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

  def has_key?(key)
    attributes.to_h.has_key?(key)
  end

  def record_class
    record_type&.to_s&.classify&.constantize
  end

  def params_class
    record_class && "#{record_class}Parameters".constantize
  end

  def parent_child_attributes
    to_h.merge(child_attributes)
  end

  def transform_as(model, options = {})
    self.record_type = model
    underscore_keys!
    map_keys!(params_class.mapping)
    run_specific_transforms(model, options)
  end

  private

  def run_specific_transforms(model, options)
    case model
    when :effort
      event = options[:event]
      normalize_gender!
      normalize_country_code!
      normalize_state_code!
      create_country_from_state!
      normalize_date!(:birthdate)
      convert_start_offset!(event.start_time)
      normalize_datetime!(:scheduled_start_time_local)
      localize_datetime!(:scheduled_start_time_local, :scheduled_start_time, event.home_time_zone)
      self[:event_id] = event.id

      # If no scheduled_start_time can be determined, set it to the event start time
      self[:scheduled_start_time] ||= event.start_time

    when :split
      event = options[:event]
      convert_split_distance!
      align_split_distance!(event.ordered_splits.map(&:distance_from_start))
      self[:course_id] = event.course_id

    when :raw_time
      event_group = options[:event_group]
      self[:split_name] ||= options[:split_name]
      self[:source] = 'File import'
      self[:event_group_id] = event_group.id

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
