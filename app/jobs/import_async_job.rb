# frozen_string_literal: true

class ImportAsyncJob
  def perform(import_job)
    ::ETL::AsyncImporter.import!(import_job)
  end
end
