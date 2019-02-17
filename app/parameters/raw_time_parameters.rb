# frozen_string_literal: true

class RawTimeParameters < BaseParameters

  def self.permitted
    %i[id event_group_id event_id lap split_name parameterized_split_name sub_split_kind bitkey bib_number sortable_bib_number
    absolute_time entered_time stopped_here with_pacer remarks source split_time_id created_by created_at pulled_by pulled_at
    effort_last_name split_time_exists data_status]
  end

  def self.enriched_query
    permitted + %i[split_id effort_id]
  end
end
