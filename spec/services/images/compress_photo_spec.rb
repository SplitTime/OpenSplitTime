# frozen_string_literal: true

require "rails_helper"

RSpec.describe Images::CompressPhoto do
  subject(:service) { described_class.new(attachment) }

  let(:effort) { create(:effort) }
  let(:attachment) { effort.photo }

  describe ".call" do
    context "when photo needs compression" do
      before do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
        effort.photo.attach(blob)
      end

      it "compresses and replaces the blob" do
        original_blob_id = attachment.blob.id
        original_size = attachment.blob.byte_size

        described_class.call(attachment)

        attachment.reload
        new_blob = attachment.blob

        expect(new_blob.id).not_to eq(original_blob_id)
        expect(new_blob.byte_size).to be < original_size
        expect(new_blob.metadata[Images::COMPRESSED_METADATA_KEY]).to eq(true)
        expect(new_blob.metadata["ost_original_byte_size"]).to eq(original_size)
        expect(new_blob.metadata["ost_compressed_at"]).to be_present
      end

      it "converts to JPEG" do
        described_class.call(attachment)

        attachment.reload
        expect(attachment.blob.content_type).to eq("image/jpeg")
      end

      it "logs the compression" do
        allow(Rails.logger).to receive(:info).and_call_original
        
        expect(Rails.logger).to receive(:info).with(/Images::CompressPhoto: Compressing photo/).ordered
        expect(Rails.logger).to receive(:info).with(/Images::CompressPhoto: Compressed photo.*reduction/).ordered

        described_class.call(attachment)
      end

      it "deletes the original blob from storage" do
        original_blob_id = attachment.blob.id

        described_class.call(attachment)

        expect(ActiveStorage::Blob.exists?(original_blob_id)).to be(false)
      end
    end

    context "when photo is already compressed" do
      before do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
        blob.update!(metadata: blob.metadata.merge(Images::COMPRESSED_METADATA_KEY => true))
        effort.photo.attach(blob)
      end

      it "skips compression" do
        original_blob_id = attachment.blob.id

        described_class.call(attachment)

        attachment.reload
        expect(attachment.blob.id).to eq(original_blob_id)
      end
    end

    context "when compression fails" do
      before do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
        effort.photo.attach(blob)
      end

      it "logs the error and re-raises" do
        allow(ImageProcessing::Vips).to receive(:source).and_raise(StandardError.new("Processing failed"))

        expect { described_class.call(attachment) }.to raise_error(StandardError, "Processing failed")
      end
    end

    context "with PNG file" do
      before do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("banner.png").open,
          filename: "banner.png",
          content_type: "image/png"
        )
        blob.update_column(:byte_size, 200.kilobytes)
        effort.photo.attach(blob)
      end

      it "converts PNG to JPEG" do
        described_class.call(attachment)

        attachment.reload
        expect(attachment.blob.content_type).to eq("image/jpeg")
        expect(attachment.blob.filename.to_s).to end_with(".jpg")
      end
    end
  end
end
