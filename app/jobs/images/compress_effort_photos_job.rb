# frozen_string_literal: true

module Images
  # Background job to compress effort photos stored in S3.
  #
  # Processes photos in batches using find_each. Skips photos that have
  # already been compressed (via metadata flag).
  #
  # Usage:
  #   Images::CompressEffortPhotosJob.perform_now
  #   Images::CompressEffortPhotosJob.perform_now(batch_size: 20, min_size_kb: 200)
  #
  class CompressEffortPhotosJob < ApplicationJob
    self.queue_adapter = :solid_queue
    queue_as :solid_default

    def perform(batch_size: 10, min_size_kb: Images::MIN_SIZE_KB)
      attachments = find_photos_to_compress(min_size_kb)

      attachments.find_each(batch_size: batch_size) do |attachment|
        next if already_compressed?(attachment.blob)

        Images::CompressPhoto.call(attachment)
      end
    end

    private

    def find_photos_to_compress(min_size_kb)
      ActiveStorage::Attachment
        .where(name: "photo", record_type: "Effort")
        .joins(:blob)
        .where("active_storage_blobs.byte_size > ?", min_size_kb.kilobytes)
    end

    def already_compressed?(blob)
      blob.metadata[Images::COMPRESSED_METADATA_KEY] == true
    end
  end
end
