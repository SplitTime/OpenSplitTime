# frozen_string_literal: true

RawTimeRow = Struct.new(:raw_times, :effort, :event, :split, :errors) do
  include ActiveModel::Serializers::JSON

  RAW_TIME_ATTRIBUTES = [:absolute_time, :entered_time, :bib_number, :split_name, :sub_split_kind, :data_status,
                         :split_time_exists, :lap, :stopped_here, :with_pacer, :remarks]
  RAW_TIME_METHODS = [:military_time, :sub_split_kind]

  def serialize
    basic_attributes.deep_transform_keys { |key| key.to_s.camelize(:lower) }
  end

  def clean?
    raw_times.all?(&:clean?)
  end

  private

  def basic_attributes
    {'raw_times' => raw_times_array, 'errors' => (errors || [])}
  end

  def raw_times_array
    (raw_times || []).map { |rt| rt.serializable_hash(only: RAW_TIME_ATTRIBUTES, methods: RAW_TIME_METHODS) }
  end
end
