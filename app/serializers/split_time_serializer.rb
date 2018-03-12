# frozen_string_literal: true

class SplitTimeSerializer < BaseSerializer
  attributes :id, :effort_id, :lap, :split_id, :bitkey, :time_from_start, :data_status, :pacer, :remarks
  link(:self) { api_v1_split_time_path(object) }
end
