# frozen_string_literal: true

RawTimeRow = Struct.new(:effort, :event, :split, :raw_times) do
  include ActiveModel::Serializers::JSON

  RAW_TIME_ATTRIBUTES = [:absolute_time, :bib_number, :split_name, :sub_split_kind, :data_status, :stopped_here, :with_pacer, :remarks]
  RAW_TIME_METHODS = [:lap, :military_time]

  def serialize
    basic_attributes.deep_transform_keys { |key| key.camelize(:lower) }
  end

  def serialize_with_effort_summary
    basic_attributes.merge('effort_summary' => effort_summary).deep_transform_keys { |key| key.camelize(:lower) }
  end

  private

  def basic_attributes
    {'effort_name' => effort&.name,
     'event_name' => event&.name,
     'event_short_name' => event&.guaranteed_short_name,
     'raw_times' => raw_times_array}
  end

  def effort_summary
    []
  end

  def raw_times_array
    raw_times.map { |rt| rt.serializable_hash(only: RAW_TIME_ATTRIBUTES, methods: RAW_TIME_METHODS) }
  end
end
