# frozen_string_literal: true

class SweepOrphanedBlobsJob < ApplicationJob
  queue_as :default

  def perform
    start_time = Time.current
    logger.info "Started SweepOrphanedBlobsJob at #{start_time}\n"

    problem_blobs = []
    orphaned_blobs = ActiveStorage::Blob.unattached

    count = orphaned_blobs.count
    if count == 0
      logger.info "No orphaned blobs found\n"
    else
      logger.info "Found #{count} orphaned blob(s)\n"

      orphaned_blobs.find_each do |blob|
        problem_blobs << blob.id unless blob.purge
      end

      if problem_blobs.present?
        logger.warn "Could not purge the following #{problem_blobs.size} blobs: #{problem_blobs.join(', ')}\n"
      else
        logger.info "Purged all #{count} orphaned blob(s)\n"
      end
    end

    duration = (Time.current - start_time).round(1)
    logger.info "Finished job in #{duration} seconds at #{Time.current}\n"
  end
end
