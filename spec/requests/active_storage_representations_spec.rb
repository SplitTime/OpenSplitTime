require "rails_helper"
require "aws-sdk-s3" # not auto-loaded in test (Disk service); needed to build the S3 error doubles below

# #2161: a variant requested for an entrant photo whose blob/file is gone used to 500; it now serves
# the placeholder, sized to the variant.
RSpec.describe "ActiveStorage representation serving", type: :request do
  let(:event_group) { event_groups(:sum) }

  let(:attachment) do
    event_group.entrant_photos.attach(
      io: file_fixture("potato3.jpg").open, filename: "188.jpg", content_type: "image/jpeg"
    )
    event_group.entrant_photos.reload.first
  end

  let(:variant_path) { rails_representation_path(attachment.variant(:small)) } # :small == resize_to_limit [200, 200]

  shared_examples "the sized placeholder" do
    it "renders the placeholder SVG sized to the variant instead of returning 500" do
      get variant_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/svg+xml")
      expect(response.body).to include(%(width="200" height="200"))
    end
  end

  context "when the underlying file is missing" do
    before { attachment.blob.service.delete(attachment.blob.key) }

    it_behaves_like "the sized placeholder"
  end

  {
    "Aws::S3::Errors::NoSuchKey" => Aws::S3::Errors::NoSuchKey.new(nil, "missing key"),
    "Aws::S3::Errors::NotFound" => Aws::S3::Errors::NotFound.new(nil, "not found"),
    "ActiveRecord::InvalidForeignKey" => ActiveRecord::InvalidForeignKey.new("fk violation"),
  }.each do |error_name, error|
    context "when serving the variant raises #{error_name}" do
      before { allow(ActiveStorage::Blob.service).to receive(:download).and_raise(error) }

      it_behaves_like "the sized placeholder"
    end
  end

  context "when serving raises an error outside the rescued set" do
    before { allow(ActiveStorage::Blob.service).to receive(:download).and_raise(Aws::S3::Errors::AccessDenied.new(nil, "denied")) }

    it "does not swallow it into the placeholder (rescue stays scoped)" do
      expect { get variant_path }.to raise_error(Aws::S3::Errors::AccessDenied)
    end
  end
end
