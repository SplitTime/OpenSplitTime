# frozen_string_literal: true

class EventGroupParameters < BaseParameters

  def self.permitted
    [:id, :slug, :name, :organization_id, :concealed, :available_live, :monitor_pacers, :data_entry_grouping_strategy,
     :home_time_zone, events_attributes: [*EventParameters.permitted], organization_attributes: [*OrganizationParameters.permitted]]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query + RawTimeParameters.permitted_query
  end
end
