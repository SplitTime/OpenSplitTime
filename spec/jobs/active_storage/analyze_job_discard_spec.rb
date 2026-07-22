require "rails_helper"

# #2161 / Scout #117837: a blob can be purged before its analyze job runs, so the analyze download hits a
# file that's gone. config/initializers/active_storage_analyze_job.rb discards those instead of erroring.
RSpec.describe ActiveStorage::AnalyzeJob do
  it "discards instead of raising when the blob's file is gone" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("potato3.jpg").open, filename: "gone.jpg", content_type: "image/jpeg"
    )
    blob.service.delete(blob.key)

    expect { described_class.perform_now(blob) }.not_to raise_error
    expect(blob.reload).not_to be_analyzed
  end
end
