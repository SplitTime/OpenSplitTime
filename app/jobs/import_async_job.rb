# frozen_string_literal: true

require "etl/etl"

class ImportAsyncJob < ApplicationJob
  def perform(import_job_id)
    import_job = ImportJob.find(import_job_id)
    ::ETL::AsyncImporter.import!(import_job)
  end
end
