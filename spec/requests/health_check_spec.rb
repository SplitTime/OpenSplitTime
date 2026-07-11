require "rails_helper"

RSpec.describe "Health Check" do
  describe "GET /up" do
    it "returns 200" do
      get "/up"
      expect(response).to have_http_status(:ok)
    end
  end
end
