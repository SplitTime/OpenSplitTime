# frozen_string_literal: true

class EventSpreadSerializer < BaseSerializer
  attributes :name, :course_name, :organization_name, :event_start_time, :display_style, :split_header_data
  link(:self) { spread_api_v1_event_path(object.event) }

  has_many :effort_times_rows
end
