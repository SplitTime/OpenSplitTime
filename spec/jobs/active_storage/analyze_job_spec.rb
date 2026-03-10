# frozen_string_literal: true

require "rails_helper"
require "vips"

RSpec.describe ActiveStorage::AnalyzeJob do
  subject(:job) { described_class.new }

  let(:effort) { create(:effort) }

  describe "#perform" do
    context "when the blob is a large image" do
      let!(:blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
        effort.photo.attach(blob)
        blob
      end

      it "compresses the photo and analyzes the result" do
        expect(Images::CompressPhoto).to receive(:call).with(blob.attachments.first)

        job.perform(blob)
      end

      context "when the image is already compressed" do
        before { blob.update!(metadata: blob.metadata.merge(Images::COMPRESSED_METADATA_KEY => true)) }

        it "analyzes without compressing" do
          expect(Images::CompressPhoto).not_to receive(:call)
          expect(blob).to receive(:analyze)

          job.perform(blob)
        end
      end

      context "when compression fails with a Vips::Error" do
        before { allow(Images::CompressPhoto).to receive(:call).and_raise(Vips::Error, "corrupt image") }

        it "reports the error to ScoutApm and falls back to analyzing the original blob" do
          expect(ScoutApm::Error).to receive(:capture).with(an_instance_of(Vips::Error))
          expect(blob).to receive(:analyze)

          job.perform(blob)
        end
      end
    end

    context "when the blob is a small image" do
      let!(:blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("banner.png").open,
          filename: "banner.png",
          content_type: "image/png"
        )
        effort.photo.attach(blob)
        blob
      end

      it "analyzes without compressing" do
        expect(Images::CompressPhoto).not_to receive(:call)
        expect(blob).to receive(:analyze)

        job.perform(blob)
      end
    end

    context "when the blob is not an image" do
      let!(:blob) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("service_form.pdf").open,
          filename: "service_form.pdf",
          content_type: "application/pdf"
        )
        effort.photo.attach(blob)
        blob
      end

      it "analyzes without compressing" do
        expect(Images::CompressPhoto).not_to receive(:call)
        expect(blob).to receive(:analyze)

        job.perform(blob)
      end
    end

    context "when the blob has no attachment" do
      let(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: file_fixture("potato3.jpg").open,
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
      end

      it "does not raise an error" do
        expect { job.perform(blob) }.not_to raise_error
      end
    end
  end
end
