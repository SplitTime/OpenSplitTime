require "rails_helper"

RSpec.describe "Efforts show_photo" do
  describe "GET show_photo" do
    let(:effort) { efforts(:ggd30_50k_bad_finish) }

    it "renders without error when the effort has no photo" do
      expect(effort.photo).not_to be_attached

      get show_photo_effort_path(effort)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No photo available")
    end
  end
end
