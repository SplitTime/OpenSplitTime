# frozen_string_literal: true

class EventGroupParameters < BaseParameters

  def self.permitted
    [:id, :slug, :name, :organization_id, :concealed, :available_live, :auto_live_times, :data_entry_grouping_strategy]
  end
end
