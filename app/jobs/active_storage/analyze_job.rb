# frozen_string_literal: true

module ActiveStorage
  # Override Rails' built-in AnalyzeJob to handle race condition with photo compression.
  #
  # ## The Problem
  #
  # When photos are uploaded, two jobs are enqueued:
  # 1. ActiveStorage::AnalyzeJob (this job) - analyzes the blob for metadata
  # 2. Images::CompressSinglePhotoJob - compresses and replaces the blob
  #
  # If CompressSinglePhotoJob runs first, it creates a new compressed blob and purges
  # the original from S3. When AnalyzeJob then tries to download the original blob,
  # it fails with Aws::S3::Errors::NotFound.
  #
  # ## The Solution
  #
  # This override:
  # 1. Checks if the blob needs compression (will be handled by CompressSinglePhotoJob)
  # 2. If yes: skips analysis (not needed, compression job sets metadata)
  # 3. If no: runs normal analysis via super
  # 4. Gracefully handles NotFound if blob was already compressed and purged
  #
  class AnalyzeJob < ActiveStorage::BaseJob
    queue_as { ActiveStorage.queues[:analysis] }

    discard_on ActiveRecord::RecordNotFound
    discard_on Aws::S3::Errors::NotFound # Blob was compressed and purged

    def perform(blob)
      # Skip analysis if blob will be compressed (compression job sets its own metadata)
      if blob_needs_compression?(blob)
        Rails.logger.info("ActiveStorage::AnalyzeJob: Skipping analysis for blob #{blob.id} (will be compressed)")
        return
      end

      # Run standard analysis
      blob.analyze
    end

    private

    def blob_needs_compression?(blob)
      blob.byte_size > Images::MIN_SIZE_KB.kilobytes &&
        blob.metadata[Images::COMPRESSED_METADATA_KEY] != true
    end
  end
end
