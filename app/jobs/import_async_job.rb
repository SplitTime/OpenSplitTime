# frozen_string_literal: true

class ImportAsyncJob
  def perform(import_job)
    ::ETL::AsyncImporter.perform(import_job)
  end
end
