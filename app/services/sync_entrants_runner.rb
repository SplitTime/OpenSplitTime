# Drives an external-service entrant sync against an ImportJob row.
# Updates status as it progresses so the user's broadcast subscription
# (broadcasts_to :user on ImportJob) renders live status changes.
class SyncEntrantsRunner
  def self.run!(import_job)
    new(import_job).run!
  end

  def initialize(import_job)
    @import_job = import_job
  end

  def run!
    import_job.start!
    import_job.update(status: :loading)

    interactor = ::Connectors::Service::SYNCING_INTERACTORS[import_job.format]
    raise UnknownServiceError, "No syncing interactor for #{import_job.format.inspect}" unless interactor

    response = interactor.perform!(import_job.parent, import_job.user)
    apply_response(response)
  rescue StandardError => e
    apply_failure(e)
    raise
  ensure
    import_job.set_elapsed_time! if import_job.persisted?
  end

  class UnknownServiceError < StandardError; end

  private

  attr_reader :import_job

  def apply_response(response)
    created = (response.resources[:created_efforts] || []).size
    updated = (response.resources[:updated_efforts] || []).size
    ignored = (response.resources[:ignored_efforts] || []).size
    deleted = (response.resources[:deleted_efforts] || []).size
    failed = response.errors.size

    import_job.update(
      status: response.successful? ? :finished : :failed,
      row_count: created + updated + ignored + deleted + failed,
      # Successes include deletions (intentional removal of withdrawn entrants).
      succeeded_count: created + updated + deleted,
      ignored_count: ignored,
      failed_count: failed,
      error_message: response.errors.any? ? response.errors.to_json : nil,
    )
  end

  def apply_failure(exception)
    import_job.update(
      status: :failed,
      error_message: [{ title: exception.class.name, detail: { messages: [exception.message] } }].to_json,
    )
  end
end
