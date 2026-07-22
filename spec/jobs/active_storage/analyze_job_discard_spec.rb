require "rails_helper"
require "aws-sdk-s3" # to build the S3 error doubles (not auto-loaded under the test Disk service)

RSpec.describe ActiveStorage::AnalyzeJob do
  # A large image takes the compress branch, so raising from CompressPhoto stands in for the missing file.
  let(:blob) do
    event_group = event_groups(:sum)
    event_group.entrant_photos.attach(
      io: file_fixture("potato3.jpg").open, filename: "1.jpg", content_type: "image/jpeg"
    )
    event_group.entrant_photos.reload.first.blob
  end

  {
    "ActiveStorage::FileNotFoundError" => ActiveStorage::FileNotFoundError.new,
    "Aws::S3::Errors::NoSuchKey" => Aws::S3::Errors::NoSuchKey.new(nil, "missing key"),
    "Aws::S3::Errors::NotFound" => Aws::S3::Errors::NotFound.new(nil, "not found"),
  }.each do |error_name, error|
    it "discards instead of failing when analysis raises #{error_name}" do
      allow(Images::CompressPhoto).to receive(:call).and_raise(error)

      expect { described_class.perform_now(blob) }.not_to raise_error
    end
  end
end
