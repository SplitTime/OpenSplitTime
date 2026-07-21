require "rails_helper"
require "vips" # read the rendered variant's real dimensions

# #2136: libvips is the sole image processor. Guards the variant path (previously untested) and
# confirms the mini_magick -> vips switch renders every declared size and serves it.
RSpec.describe "Active Storage variant rendering", type: :request do
  let(:event_group) { event_groups(:sum) }

  before do
    event_group.entrant_photos.attach(
      io: file_fixture("potato3.jpg").open, filename: "1.jpg", content_type: "image/jpeg"
    )
  end

  it "is configured to use the vips processor" do
    expect(Rails.application.config.active_storage.variant_processor).to eq(:vips)
  end

  it "renders each declared variant scaled to fit its size limit" do
    photo = event_group.entrant_photos.reload.first

    # potato3.jpg is larger than every limit, so resize_to_limit shrinks the longer side to exactly it.
    { thumbnail: 50, small: 200 }.each do |name, limit|
      photo.variant(name).processed.image.blob.open do |file|
        image = Vips::Image.new_from_file(file.path)
        expect([image.width, image.height].max).to eq(limit)
      end
    end
  end

  it "serves the rendered variant through the representation endpoint" do
    get rails_representation_path(event_group.entrant_photos.reload.first.variant(:small))

    expect(response).to have_http_status(:redirect)
    expect(response.location).not_to include("avatar-placeholder")
  end
end
