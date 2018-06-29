# frozen_string_literal: true

RawTimeRow = Struct.new(:raw_times, :effort, :event, :split, :errors) do
  include ActiveModel::Serializers::JSON

  RAW_TIME_ATTRIBUTES = [:absolute_time, :bib_number, :split_name, :sub_split_kind, :data_status,
                         :existing_times_count, :stopped_here, :with_pacer, :remarks]
  RAW_TIME_METHODS = [:lap, :military_time, :sub_split_kind]

  def serialize
    basic_attributes.deep_transform_keys { |key| key.camelize(:lower) }
  end

  def serialize_with_effort_overview
    basic_attributes.merge('effort_overview' => effort_overview).deep_transform_keys { |key| key.camelize(:lower) }
  end

  private

  def basic_attributes
    {'raw_times' => raw_times_array, 'errors' => (errors || [])}
  end

  def effort_overview
    []
  end

  def raw_times_array
    (raw_times || []).map { |rt| rt.serializable_hash(only: RAW_TIME_ATTRIBUTES, methods: RAW_TIME_METHODS) }
  end
end
