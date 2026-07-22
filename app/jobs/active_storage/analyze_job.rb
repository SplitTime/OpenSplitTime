# frozen_string_literal: true

module ActiveStorage
  # Override Rails' built-in AnalyzeJob to compress photos before analysis.
  #
  # Rails automatically enqueues AnalyzeJob when a blob is attached. We override it to:
  # - Check if the blob needs compression (file size > Images::MIN_SIZE_KB)
  # - If yes: compress it synchronously, then analyze the compressed blob
  # - If no: run normal analysis
  class AnalyzeJob < ActiveStorage::BaseJob
    queue_as { ActiveStorage.queues[:analysis] }

    discard_on ActiveRecord::RecordNotFound
    # A blob can be purged before this job runs (the entrant-photo workflow re-parents/deletes
    # attachments right after upload), so the file may already be gone -- nothing to analyze, discard.
    # Aws errors are strings so they resolve lazily at raise time; aws-sdk-s3 is require: false.
    discard_on ActiveStorage::FileNotFoundError, "Aws::S3::Errors::NoSuchKey", "Aws::S3::Errors::NotFound"
    retry_on ActiveStorage::IntegrityError, attempts: 10, wait: :polynomially_longer

    def perform(blob)
      if blob_needs_compression?(blob)
        compress_and_analyze(blob)
      else
        blob.analyze
      end
    end

    private

    def blob_needs_compression?(blob)
      blob.image? &&
        blob.byte_size > Images::MIN_SIZE_KB.kilobytes &&
        blob.metadata[Images::COMPRESSED_METADATA_KEY] != true
    end

    def compress_and_analyze(blob)
      attachment = blob.attachments.first
      return unless attachment

      Images::CompressPhoto.call(attachment)
      attachment.blob.analyze
    rescue Vips::Error => e
      ScoutApm::Error.capture(e)
      blob.analyze
    end
  end
end
