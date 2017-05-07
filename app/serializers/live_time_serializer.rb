class LiveTimeSerializer < BaseSerializer
  attributes :id, :event_id, :lap, :split_id, :split_extension, :absolute_time, :stopped_here, :with_pacer, :remarks
  link(:self) { api_v1_live_time_path(object) }

  belongs_to :event
  belongs_to :split
end
