class EventSpreadSerializer < BaseSerializer
  attributes :name, :course_name, :organization_name, :event_start_time, :display_style, :split_header_data

  has_many :effort_times_rows
end