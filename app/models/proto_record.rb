require "etl"
require "ostruct"

class ProtoRecord
  include Etl::Transformable

  attr_accessor :record_type, :record_action
  attr_reader :children, :attributes

  def initialize(args = {})
    @record_type = args[:record_type]&.to_sym
    @record_action = args[:record_action]&.to_sym
    @children = Array.wrap(args[:children]) || []
    @attributes = OpenStruct.new(args.to_h.except(nil, :record_type, :record_action, :children)) # rubocop:disable Style/OpenStructUse
    validate_setup
  end

  delegate :[]=, :to_h, :delete_field, to: :attributes

  def [](key)
    key.nil? ? nil : attributes[key]
  end

  def ==(other)
    record_type == other.record_type &&
      record_action == other.record_action &&
      attributes == other.attributes &&
      children == other.children
  end

  def deep_dup
    new_proto_record = ProtoRecord.new(record_type: record_type, record_action: record_action)

    attributes.to_h.each do |key, value|
      new_proto_record[key] = value.deep_dup
    end

    children.each do |child|
      new_proto_record.children << child.deep_dup
    end

    new_proto_record
  end

  def key?(key)
    attributes.to_h.key?(key)
  end
  alias has_key? key?

  def keys
    attributes.to_h.keys
  end

  def record_class
    return if record_type.blank?

    record_type.to_s.classify.constantize
  end

  def params_class
    record_class && "#{record_class}Parameters".constantize
  end

  def parent_child_attributes
    to_h.merge(child_attributes)
  end

  def marked_for_destruction?
    record_action == :destroy
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
      transfer_identified_gender!
      normalize_gender!
      normalize_country_code!
      normalize_state_code!
      create_country_from_state!
      normalize_date!(:birthdate)
      add_date_to_time!(:scheduled_start_time_local, event.scheduled_start_time_local.to_date)
      normalize_datetime!(:scheduled_start_time_local)
      localize_datetime!(:scheduled_start_time_local, :scheduled_start_time, event.home_time_zone)
      convert_start_offset!(event.scheduled_start_time) if self[:scheduled_start_time].nil?
      self[:event_id] = event.id

      # If no scheduled_start_time can be determined, set it to the event scheduled start time
      self[:scheduled_start_time] ||= event.scheduled_start_time

    when :historical_fact
      organization = options[:organization]
      normalize_gender!
      clear_zero_values!(:email, :phone, :address, :city, :state_code, :country_code)
      remove_redundant_state_code!
      normalize_country_code!
      normalize_state_code!
      create_country_from_state!
      normalize_date!(:birthdate)
      slice_permitted!
      self[:organization_id] = organization.id

    when :lottery_entrant
      division = options[:division]
      normalize_gender!
      normalize_country_code!
      normalize_state_code!
      create_country_from_state!
      normalize_date!(:birthdate)
      self[:lottery_division_id] = division.id

    when :split
      event = options[:event]
      normalize_split_kind!
      convert_split_distance!
      align_split_distance!(event.ordered_splits.map(&:distance_from_start))
      self[:course_id] = event.course_id

    when :raw_time
      event_group = options[:event_group]
      self[:split_name] ||= options[:split_name]
      self[:source] = "File import"
      self[:event_group_id] = event_group.id

    end
  end

  def child_attributes
    children.group_by(&:record_type).to_h do |record_type, proto_records|
      ["#{record_type.to_s.pluralize}_attributes", proto_records.map(&:to_h)]
    end
  end

  def validate_setup
    return if children.all?(ProtoRecord)

    raise ArgumentError, "children of a ProtoRecord must be ProtoRecords"
  end
end
