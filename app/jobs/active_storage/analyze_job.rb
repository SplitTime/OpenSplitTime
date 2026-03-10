# frozen_string_literal: true

module ActiveStorage
  # Override Rails' built-in AnalyzeJob to compress photos before analysis.
  #
  # ## Why Override?
  #
  # Rails automatically enqueues AnalyzeJob when a blob is attached. We override it to:
  # 1. Check if the blob needs compression (photos > 100KB)
  # 2. If yes: compress it synchronously, then analyze the compressed blob
  # 3. If no: run normal analysis
  #
  # ## Benefits
  #
  # - Eliminates race condition (previously two separate jobs could conflict)
  # - Simplifies code (no need for separate compress job + callbacks in models)
  # - Already running in background, so compression time doesn't hurt response times
  # - Compressed blobs get analyzed with accurate metadata (dimensions, etc.)
  #
  class AnalyzeJob < ActiveStorage::BaseJob
    queue_as { ActiveStorage.queues[:analysis] }

    discard_on ActiveRecord::RecordNotFound

    def perform(blob)
      if blob_needs_compression?(blob)
        compress_and_analyze(blob)
      else
        blob.analyze
      end
    end

    private

    def blob_needs_compression?(blob)
      blob.byte_size > Images::MIN_SIZE_KB.kilobytes &&
        blob.metadata[Images::COMPRESSED_METADATA_KEY] != true
    end

    def compress_and_analyze(blob)
      # Find the attachment(s) using this blob
      attachment = blob.attachments.first
      
      unless attachment
        Rails.logger.warn("ActiveStorage::AnalyzeJob: No attachment found for blob #{blob.id}, skipping compression")
        return
      end

      Rails.logger.info("ActiveStorage::AnalyzeJob: Compressing blob #{blob.id} before analysis")
      
      # Compress the photo (creates new blob and updates attachment)
      Images::CompressPhoto.call(attachment)
      
      # Analyze the compressed blob (attachment.blob is now the new compressed blob)
      attachment.blob.analyze
    rescue => e
      Rails.logger.error("ActiveStorage::AnalyzeJob: Failed to compress blob #{blob.id}: #{e.message}")
      # Fall back to analyzing original blob if compression fails
      blob.analyze
    end
  end
end
