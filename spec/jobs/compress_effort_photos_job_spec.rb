# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompressEffortPhotosJob do
  subject(:job) { described_class.new }

  let(:perform_job) { job.perform(batch_size: batch_size, min_size_kb: min_size_kb) }
  let(:batch_size) { 10 }
  let(:min_size_kb) { 100 }

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

      it "replaces the original blob with a compressed version" do
        original_blob_id = original_blob.id
        original_size = original_blob.byte_size

        relation = described_class.new.send(:find_photos_to_compress, min_size_kb)
        expect(relation.count).to eq(1)
        expect(described_class.new.send(:already_compressed?, original_blob)).to eq(false)

        attachment = ActiveStorage::Attachment.find_by!(name: "photo", record_type: "Effort", record_id: effort.id)

        expect { job.send(:compress_photo, attachment) }.not_to raise_error

        effort.reload
        new_blob = effort.photo.blob

        expect(new_blob.id).not_to eq(original_blob_id)
        expect(new_blob).to be_present
        expect(new_blob.byte_size).to be < original_size
        expect(new_blob.metadata[described_class::COMPRESSED_METADATA_KEY]).to eq(true)
      end
    end

    context "when a PNG photo is attached" do
      let!(:original_blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("banner.png").open,
          filename: "banner.png",
          content_type: "image/png"
        )
        blob.update_column(:byte_size, 150.kilobytes)
        effort.photo.attach(blob)
        blob
      end

      it "processes PNG files" do
        expect { perform_job }.not_to raise_error
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
        expect { perform_job }.not_to raise_error

        effort.reload
        expect(effort.photo.blob.id).to eq(original_blob.id)
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
