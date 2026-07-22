require "rails_helper"
require "aws-sdk-s3" # not auto-loaded in test (Disk service); needed to build the S3 error doubles

# #2161 / Scout #117837: a blob can be purged before its analyze job runs, so analysis hits a file that's
# gone. ActiveStorage::AnalyzeJob (app/jobs/active_storage/analyze_job.rb) discards those errors rather
# than failing/retrying a file that won't come back.
RSpec.describe ActiveStorage::AnalyzeJob do
  # potato3.jpg is a large, uncompressed image, so perform takes the compress branch; raising from there
  # simulates the file being gone by the time the job runs.
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
