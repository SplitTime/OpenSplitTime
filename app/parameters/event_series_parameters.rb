class EventSeriesParameters < BaseParameters
  def self.permitted
    [:id, :name, :slug, :results_template_id, :scoring_method, {event_ids: []}]
  end
end
