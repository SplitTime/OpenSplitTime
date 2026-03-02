# frozen_string_literal: true

require "rails_helper"

RSpec.describe Images::CompressSinglePhotoJob do
  subject(:job) { described_class.new }

  let(:effort) { create(:effort) }
  let(:perform_job) { job.perform(effort.photo.id) }

  describe "#perform" do
    context "when attachment exists and needs compression" do
      let!(:blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
        effort.photo.attach(blob)
        blob
      end

      it "calls Images::CompressPhoto" do
        expect(Images::CompressPhoto).to receive(:call).once

        job.perform(effort.photo.id)
      end
    end

    context "when attachment is too small" do
      let!(:small_blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("banner.png").open,
          filename: "banner.png",
          content_type: "image/png"
        )
        effort.photo.attach(blob)
        blob
      end

      it "skips compression" do
        expect(Images::CompressPhoto).not_to receive(:call)

        job.perform(effort.photo.id)
      end
    end

    context "when attachment is already compressed" do
      let!(:compressed_blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
        blob.update!(metadata: blob.metadata.merge(Images::COMPRESSED_METADATA_KEY => true))
        effort.photo.attach(blob)
        blob
      end

      it "skips compression" do
        expect(Images::CompressPhoto).not_to receive(:call)

        job.perform(effort.photo.id)
      end
    end

    context "when attachment does not exist" do
      it "logs a warning and does not raise an error" do
        expect(Rails.logger).to receive(:warn).with(/Attachment .* not found/)

        expect { job.perform(999999) }.not_to raise_error
      end
    end


  end
end
