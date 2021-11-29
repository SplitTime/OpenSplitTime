# frozen_string_literal: true

class ReportAnalyticsJob < ApplicationJob

  queue_as :default

  def perform(ga_params)
    AnalyticsReporter.report_to_ga(ga_params: ga_params, http_client: RestClient)
  end
end
