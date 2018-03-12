# frozen_string_literal: true

class LiveTimeParameters < BaseParameters

  def self.permitted
    [:id, :event_id, :lap, :split_id, :sub_split_kind, :bitkey, :wave, :bib_number, :absolute_time, :military_time,
     :stopped_here, :with_pacer, :remarks, :batch, :source, :event_slug, :split_slug, :split_time_id, :pulled_by]
  end
end
