# frozen_string_literal: true

class EventSeriesParameters < BaseParameters

  def self.permitted
    [:id, :name, :slug, :organization_id, :results_template_id, :scoring_method, event_ids: []]
  end
end
