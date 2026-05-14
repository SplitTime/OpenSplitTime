require "rails_helper"

RSpec.describe "OrganizationUsagesController" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:non_admin_user) { users(:third_user) }

  after { Warden.test_reset! }

  describe "GET /organization-usage" do
    context "when not signed in" do
      it "redirects away" do
        get organization_usages_path

        expect(response).to have_http_status(:redirect)
        expect(response.location).not_to include("/organization-usage")
      end
    end

    context "when signed in as a non-admin" do
      before { login_as non_admin_user, scope: :user }

      it "redirects with an access-denied alert" do
        get organization_usages_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end

    context "when signed in as an admin" do
      before { login_as admin_user, scope: :user }

      it "renders successfully" do
        get organization_usages_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Organization Usage")
      end

      it "lists organizations under both For-Profit and Non-Profit headings" do
        get organization_usages_path

        expect(response.body).to include("For-Profit")
        expect(response.body).to include("Non-Profit")
        non_profit_half = response.body.split("Non-Profit", 2).last
        expect(non_profit_half).to include("Running Up For Air")
      end

      it "excludes organizations with no real efforts" do
        empty_org = Organization.create!(
          name: "Org With Nothing",
          created_by: admin_user.id,
          concealed: false,
        )

        get organization_usages_path

        expect(response.body).not_to include(empty_org.name)
      end
    end
  end

  describe "GET /organization-usage/:id" do
    let(:hardrock) { organizations(:hardrock) }

    context "when signed in as a non-admin" do
      before { login_as non_admin_user, scope: :user }

      it "redirects with an access-denied alert" do
        get organization_usage_path(hardrock)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end

    context "when signed in as an admin" do
      before { login_as admin_user, scope: :user }

      it "renders the organization name and a chart" do
        get organization_usage_path(hardrock)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Hardrock")
        expect(response.body).to include("Efforts by year")
      end

      it "shows the empty-state message when the org has no real efforts" do
        hardrock.event_groups.update_all(concealed: true)

        get organization_usage_path(hardrock)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No real efforts recorded")
      end

      it "renders the admin-only donations section with totals and the per-donation table" do
        get organization_usage_path(hardrock)

        expect(response.body).to include("Donations")
        expect(response.body).to include("admin only")
        expect(response.body).to include("Total Donated")
        # hardrock_check_2025 fixture: $500.00 check on 2025-03-04
        expect(response.body).to include("$500.00")
        expect(response.body).to include("Check")
      end

      it "shows an empty-state message inside the donations section when the org has none" do
        # dirty_30_running fixture has real efforts but no monetary_donations
        dirty_30 = organizations(:dirty_30_running)
        expect(dirty_30.monetary_donations).to be_empty

        get organization_usage_path(dirty_30)

        expect(response.body).to include("No donations recorded for this organization")
      end
    end
  end
end
