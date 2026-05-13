require "rails_helper"

RSpec.describe "Madmin::MonetaryDonationsController" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }

  before { login_as admin_user, scope: :user }
  after { Warden.test_reset! }

  it "renders the index" do
    get "/madmin/monetary_donations"

    expect(response).to have_http_status(:ok)
  end

  it "renders the new form" do
    get "/madmin/monetary_donations/new"

    expect(response).to have_http_status(:ok)
  end

  it "renders the show page for an existing donation" do
    donation = monetary_donations(:hardrock_paypal_2024)

    get "/madmin/monetary_donations/#{donation.id}"

    expect(response).to have_http_status(:ok)
  end
end
