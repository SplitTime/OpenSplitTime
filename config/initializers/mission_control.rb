# TODO: Remove this initializer after fully migrating from Sidekiq to Solid Queue.
# Once `config.active_job.queue_adapter = :solid_queue` is set in the environment
# configs, Mission Control will auto-detect the adapter and this file can be deleted.
MissionControl::Jobs.adapters = [:solid_queue]
MissionControl::Jobs.http_basic_auth_enabled = false

unless ActiveJob::QueueAdapters::SolidQueueAdapter.ancestors.include?(ActiveJob::QueueAdapters::SolidQueueExt)
  ActiveJob::QueueAdapters::SolidQueueAdapter.prepend ActiveJob::QueueAdapters::SolidQueueExt
end
