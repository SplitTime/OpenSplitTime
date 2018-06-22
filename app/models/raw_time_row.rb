# frozen_string_literal: true

RawTimeRow = Struct.new(:effort, :event, :split, :raw_times) do
  include ActiveModel::Serializers::JSON

  def serialize
    {'effort' => effort_hash,
     'event' => event_hash,
     'split' => split_hash,
     'raw_times' => raw_times_array}
  end

  private

  def effort_hash
    effort&.serializable_hash(only: [:first_name, :last_name, :bib_number], include: {split_times: {only: [:stopped_here, :data_status], methods: [:day_and_time, :split_name]}})
  end

  def event_hash
    event&.serializable_hash(only: [:name], methods: [:guaranteed_short_name])
  end

  def split_hash
    split&.serializable_hash(only: [:base_name])
  end

  def raw_times_array
    raw_times.map { |rt| rt.serializable_hash(only: [:absolute_time, :entered_time], methods: :military_time) }
  end
end
