require "rails_helper"

RSpec.describe "Madmin::MonetaryDonationsController" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:donation) { monetary_donations(:hardrock_paypal_2024) }

  before { login_as admin_user, scope: :user }
  after { Warden.test_reset! }

  describe "GET /madmin/monetary_donations" do
    it "renders the index" do
      get "/madmin/monetary_donations"

      expect(response).to have_http_status(:ok)
    end

    it "shows the organization name, amount, source, and date columns" do
      get "/madmin/monetary_donations"

      expect(response.body).to include(donation.organization.name)
      expect(response.body).to include(donation.received_on.to_s)
      expect(response.body).to include("paypal")
    end
  end

  describe "GET /madmin/monetary_donations/new" do
    it "renders the new form" do
      get "/madmin/monetary_donations/new"

      expect(response).to have_http_status(:ok)
    end

    it "renders the Organization dropdown with org names rather than 'Organization #N'" do
      get "/madmin/monetary_donations/new"

      expect(response.body).to include("<option")
      expect(response.body).to include("Hardrock")
      expect(response.body).not_to match(/Organization #\d+/)
    end
  end

  describe "GET /madmin/monetary_donations/:id" do
    it "renders the show page" do
      get "/madmin/monetary_donations/#{donation.id}"

      expect(response).to have_http_status(:ok)
    end
  end
end
