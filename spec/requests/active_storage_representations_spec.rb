require "rails_helper"
require "aws-sdk-s3" # not auto-loaded in the test env (Disk service); needed to build the error doubles below

# Regression coverage for #2161: the entrant-photo management workflow can request a variant for a
# photo whose blob/file is mid-purge or already gone, which made the stock representation controller
# 500. config/initializers/active_storage_representations.rb rescues that class of errors and serves
# the empty-avatar placeholder instead.
RSpec.describe "ActiveStorage representation serving", type: :request do
  let(:event_group) { event_groups(:sum) }

  let(:attachment) do
    event_group.entrant_photos.attach(
      io: file_fixture("potato3.jpg").open, filename: "188.jpg", content_type: "image/jpeg"
    )
    event_group.entrant_photos.reload.first
  end

  let(:variant_path) { rails_representation_path(attachment.variant(:small)) }

  context "when the underlying file is missing" do
    before { attachment.blob.service.delete(attachment.blob.key) }

    it "redirects to the placeholder instead of returning 500" do
      get variant_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("avatar-placeholder")
    end
  end

  {
    "Aws::S3::Errors::NoSuchKey" => Aws::S3::Errors::NoSuchKey.new(nil, "missing key"),
    "Aws::S3::Errors::NotFound" => Aws::S3::Errors::NotFound.new(nil, "not found"),
    "ActiveRecord::InvalidForeignKey" => ActiveRecord::InvalidForeignKey.new("fk violation"),
  }.each do |error_name, error|
    context "when serving the variant raises #{error_name}" do
      before { allow(ActiveStorage::Blob.service).to receive(:download).and_raise(error) }

      it "redirects to the placeholder instead of returning 500" do
        get variant_path

        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("avatar-placeholder")
      end
    end
  end

  context "when serving raises an error outside the rescued set" do
    before { allow(ActiveStorage::Blob.service).to receive(:download).and_raise(Aws::S3::Errors::AccessDenied.new(nil, "denied")) }

    it "does not swallow it into the placeholder (rescue stays scoped)" do
      expect { get variant_path }.to raise_error(Aws::S3::Errors::AccessDenied)
    end
  end
end
