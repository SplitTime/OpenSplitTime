# frozen_string_literal: true

require "rails_helper"

RSpec.describe Images::CompressEffortPhotosJob do
  subject(:job) { described_class.new }

  let(:perform_job) { job.perform(batch_size: batch_size, min_size_kb: min_size_kb) }
  let(:batch_size) { 10 }
  let(:min_size_kb) { Images::MIN_SIZE_KB }

  let(:effort) { create(:effort) }

  describe "#perform" do
    context "when there are no photos to compress" do
      it "completes without errors" do
        expect { perform_job }.not_to raise_error
      end
    end

    context "when there are photos larger than the minimum size" do
      let(:min_size_kb) { 1 }

      let!(:original_blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
        effort.photo.attach(blob)
        blob
      end

      it "calls Images::CompressPhoto for the attachment" do
        expect(Images::CompressPhoto).to receive(:call).once

        perform_job
      end

      it "skips already compressed photos" do
        original_blob.update!(metadata: original_blob.metadata.merge(Images::COMPRESSED_METADATA_KEY => true))

        expect(Images::CompressPhoto).not_to receive(:call)

        perform_job
      end
    end

    context "when there are photos smaller than the minimum size" do
      let!(:original_blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("banner.png").open,
          filename: "banner.png",
          content_type: "image/png"
        )
        effort.photo.attach(blob)
        blob
      end

      it "does not process the photo" do
        expect(Images::CompressPhoto).not_to receive(:call)

        perform_job
      end
    end

    context "when batch_size is specified" do
      let(:batch_size) { 2 }
      let(:efforts) { create_list(:effort, 5) }

      before do
        efforts.each do |e|
          blob = ActiveStorage::Blob.create_and_upload!(
            io: file_fixture("potato3.jpg").open,
            filename: "potato3.jpg",
            content_type: "image/jpeg"
          )
          e.photo.attach(blob)
        end
      end

      it "uses find_each batching" do
        photos_before = ActiveStorage::Attachment
                        .where(name: "photo", record_type: "Effort")
                        .joins(:blob)
                        .where("active_storage_blobs.byte_size > ?", min_size_kb.kilobytes)
                        .count

        expect(photos_before).to eq(5)

        expect { perform_job }.not_to raise_error
      end
    end
  end
end
