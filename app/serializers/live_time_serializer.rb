# frozen_string_literal: true

class LiveTimeSerializer < BaseSerializer
  attributes :id, :event_id, :bib_number, :split_id, :sub_split_kind, :bitkey, :absolute_time, :stopped_here,
             :with_pacer, :remarks, :batch, :source, :event_slug, :split_slug, :split_time_id, :pulled_by
  link(:self) { api_v1_live_time_path(object) }

  belongs_to :event
  belongs_to :split
end
