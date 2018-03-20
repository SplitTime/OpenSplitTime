# frozen_string_literal: true

class RawTimeParameters < BaseParameters

  def self.permitted
    [:id, :event_group_id, :split_name, :sub_split_kind, :bitkey, :bib_number, :absolute_time, :military_time,
     :stopped_here, :with_pacer, :remarks, :source, :split_time_id, :pulled_by]
  end
end
