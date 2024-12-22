# frozen_string_literal: true

require "etl"

class ImportAsyncJob < ApplicationJob
  def perform(import_job_id)
    import_job = ImportJob.find(import_job_id)
    set_current_user(current_user: import_job.user)

    ::Etl::AsyncImporter.import!(import_job)
  end
end
