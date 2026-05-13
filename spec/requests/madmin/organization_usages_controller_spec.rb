require "rails_helper"

RSpec.describe "Madmin::OrganizationUsagesController" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:non_admin_user) { users(:third_user) }

  after { Warden.test_reset! }

  describe "GET /madmin/organization-usage" do
    context "when signed in as a non-admin" do
      before { login_as non_admin_user, scope: :user }

      it "redirects with an unauthorized alert" do
        get madmin_organization_usages_path

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end

    context "when signed in as an admin" do
      before { login_as admin_user, scope: :user }

      it "renders successfully" do
        get madmin_organization_usages_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Organization Usage")
      end

      it "lists organizations under both For-Profit and Non-Profit headings" do
        get madmin_organization_usages_path

        expect(response.body).to include("For-Profit")
        expect(response.body).to include("Non-Profit")
        # Running Up For Air is the lone non_profit: true fixture
        non_profit_half = response.body.split("Non-Profit", 2).last
        expect(non_profit_half).to include("Running Up For Air")
      end

      it "excludes organizations with no real efforts" do
        empty_org = Organization.create!(
          name: "Org With Nothing",
          created_by: admin_user.id,
          concealed: false,
        )

        get madmin_organization_usages_path

        expect(response.body).not_to include(empty_org.name)
      end
    end
  end

  describe "GET /madmin/organization-usage/:id" do
    let(:hardrock) { organizations(:hardrock) }

    context "when signed in as a non-admin" do
      before { login_as non_admin_user, scope: :user }

      it "redirects with an unauthorized alert" do
        get madmin_organization_usage_path(hardrock)

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end

    context "when signed in as an admin" do
      before { login_as admin_user, scope: :user }

      it "renders the organization name and a chart" do
        get madmin_organization_usage_path(hardrock)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Hardrock")
        expect(response.body).to include("Efforts by year")
      end

      it "shows the empty-state message when the org has no real efforts" do
        hardrock.event_groups.update_all(concealed: true)

        get madmin_organization_usage_path(hardrock)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No real efforts recorded")
      end
    end
  end
end
