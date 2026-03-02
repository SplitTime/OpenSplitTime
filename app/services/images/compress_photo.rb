# frozen_string_literal: true

module Images
  # Service to compress a single photo attachment.
  #
  # Handles downloading, compressing, uploading, and replacing the blob.
  #
  class CompressPhoto
    def self.call(attachment)
      new(attachment).call
    end

    def initialize(attachment)
      @attachment = attachment
    end

    def call
      return if already_compressed?

      compress_and_replace
    end

    private

    attr_reader :attachment

    def already_compressed?
      attachment.blob.metadata[Images::COMPRESSED_METADATA_KEY] == true
    end

    def compress_and_replace
      blob = attachment.blob
      original_size = blob.byte_size

      Rails.logger.info("Images::CompressPhoto: Compressing photo #{attachment.id} (#{blob.filename}, #{original_size} bytes)")

      tempfile = nil
      processed = nil

      begin
        tempfile = download_blob(blob)
        processed = compress_image(tempfile)
        new_blob = upload_compressed_blob(processed, blob.filename, original_size)
        replace_blob(blob, new_blob)

        Rails.logger.info("Images::CompressPhoto: Compressed photo #{attachment.id}: #{original_size} → #{new_blob.byte_size} bytes (#{reduction_percent(original_size, new_blob.byte_size)}% reduction)")
      ensure
        cleanup_tempfiles(tempfile, processed)
      end
    end

    def download_blob(blob)
      tempfile = Tempfile.new(["photo", File.extname(blob.filename.to_s)])
      tempfile.binmode
      blob.download { |chunk| tempfile.write(chunk) }
      tempfile.rewind
      tempfile
    end

    def compress_image(tempfile)
      ImageProcessing::Vips
        .source(tempfile)
        .resize_to_limit(Images::MAX_DIMENSION, Images::MAX_DIMENSION)
        .convert("jpg")
        .saver(quality: Images::JPEG_QUALITY, strip: true)
        .call
    end

    def upload_compressed_blob(processed, original_filename, original_size)
      filename = original_filename.to_s.sub(/\.png$/i, ".jpg")

      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(processed.path),
        filename: filename,
        content_type: "image/jpeg"
      )

      blob.update!(metadata: blob.metadata.merge(
        Images::COMPRESSED_METADATA_KEY => true,
        "ost_original_byte_size" => original_size,
        "ost_compressed_at" => Time.current.iso8601
      ))

      blob
    end

    def replace_blob(old_blob, new_blob)
      old_blob_id = old_blob.id
      attachment.update!(blob: new_blob)
      ActiveStorage::Blob.find(old_blob_id).purge
    end

    def cleanup_tempfiles(tempfile, processed)
      tempfile&.close
      tempfile&.unlink
      processed&.unlink if processed
    end

    def reduction_percent(original_size, new_size)
      ((original_size - new_size).to_f / original_size * 100).round(1)
    end
  end
end
