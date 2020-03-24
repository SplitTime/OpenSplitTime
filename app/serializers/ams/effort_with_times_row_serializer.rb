# frozen_string_literal: true

class EffortWithTimesRowSerializer < BaseSerializer
  attributes :event_short_name, :event_split_header_data
  type :effort_with_times_row

  has_one :effort_times_row
end
