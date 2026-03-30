require "rails_helper"

RSpec.describe "Docs Redirects" do
  describe "GET /documentation" do
    it "redirects to new docs site" do
      get "/documentation"
      expect(response).to redirect_to("https://docs.opensplittime.org")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /docs" do
    it "redirects to new docs site" do
      get "/docs"
      expect(response).to redirect_to("https://docs.opensplittime.org")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /docs/contents" do
    it "redirects to new docs site" do
      get "/docs/contents"
      expect(response).to redirect_to("https://docs.opensplittime.org")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /docs/getting_started" do
    it "redirects to new docs site getting started section" do
      get "/docs/getting_started"
      expect(response).to redirect_to("https://docs.opensplittime.org/getting-started/")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /docs/management" do
    it "redirects to new docs site management section" do
      get "/docs/management"
      expect(response).to redirect_to("https://docs.opensplittime.org/management/")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /docs/ost_remote" do
    it "redirects to new docs site ost-remote section" do
      get "/docs/ost_remote"
      expect(response).to redirect_to("https://docs.opensplittime.org/ost-remote/")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /docs/api" do
    it "redirects to new docs site api section" do
      get "/docs/api"
      expect(response).to redirect_to("https://docs.opensplittime.org/api/")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /docs/user_info" do
    it "redirects to new docs site user-info section" do
      get "/docs/user_info"
      expect(response).to redirect_to("https://docs.opensplittime.org/user-info/")
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
