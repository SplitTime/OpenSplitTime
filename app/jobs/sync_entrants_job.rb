class SyncEntrantsJob < ApplicationJob
  queue_as :default

  def perform(import_job_id)
    import_job = ImportJob.find(import_job_id)
    set_current_user(current_user: import_job.user)

    ::SyncEntrantsRunner.run!(import_job)
  end
end
