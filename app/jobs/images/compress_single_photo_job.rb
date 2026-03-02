# frozen_string_literal: true

module Images
  # Background job to compress a single photo attachment.
  #
  # Triggered by after_commit callback when an effort photo is uploaded.
  # Skips photos that are too small or already compressed.
  #
  # Usage:
  #   Images::CompressSinglePhotoJob.perform_later(attachment_id)
  #
  class CompressSinglePhotoJob < ApplicationJob
    queue_as :default

    def perform(attachment_id)
      attachment = ActiveStorage::Attachment.find(attachment_id)

      return if skip_compression?(attachment)

      Images::CompressPhoto.call(attachment)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Images::CompressSinglePhotoJob: Attachment #{attachment_id} not found")
    rescue StandardError => e
      Rails.logger.error("Images::CompressSinglePhotoJob: Failed to compress attachment #{attachment_id}: #{e.message}")
    end

    private

    def skip_compression?(attachment)
      attachment.blob.byte_size <= Images::MIN_SIZE_KB.kilobytes ||
        attachment.blob.metadata[Images::COMPRESSED_METADATA_KEY] == true
    end
  end
end
