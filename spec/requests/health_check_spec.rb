require "rails_helper"

RSpec.describe "Health Check" do
  describe "GET /up" do
    it "returns 200" do
      get "/up"
      expect(response).to have_http_status(:ok)
    end
  end

  # Bots probe /up.php etc.; the format extension must not 500 the health controller.
  describe "GET /up.php" do
    it "returns 406 rather than raising" do
      get "/up.php"
      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
