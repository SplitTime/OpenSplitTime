require "etl"

class ImportAsyncJob < ApplicationJob
  self.queue_adapter = :solid_queue
  queue_as :solid_default

  def perform(import_job_id)
    import_job = ImportJob.find(import_job_id)
    set_current_user(current_user: import_job.user)

    ::Etl::AsyncImporter.import!(import_job)
  end
end
