# frozen_string_literal: true

class RawTimeParameters < BaseParameters

  def self.permitted
    [:absolute_time,
     :bib_number,
     :bitkey,
     :created_at,
     :created_by,
     :data_status,
     :disassociated_from_effort,
     :effort_last_name,
     :entered_lap,
     :entered_time,
     :event_group_id,
     :event_id,
     :id,
     :parameterized_split_name,
     :pulled_at,
     :pulled_by,
     :remarks,
     :sortable_bib_number,
     :source,
     :split_name,
     :split_time_exists,
     :split_time_id,
     :stopped_here,
     :sub_split_kind,
     :with_pacer]
  end

  def self.enriched_query
    permitted + [:split_id, :effort_id]
  end
end
