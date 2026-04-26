require "rails_helper"

RSpec.describe "Efforts#mini_table" do
  include Warden::Test::Helpers

  subject(:make_request) do
    post mini_table_efforts_path,
         params: { effort_ids: [effort.id], target: "popover_target" },
         as: :json,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  let(:effort) { efforts(:hardrock_2014_keith_metz) }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }

  before { effort.person.update!(obscure_name: true, hide_age: true) }

  after { Warden.test_reset! }

  context "when the viewer is unauthenticated" do
    it "shows initials and obscures the age" do
      make_request

      expect(response.body).to include("K. M.")
      expect(response.body).not_to include("Keith")
      expect(response.body).not_to include("Metz")
      expect(response.body).not_to match(/Male, \d+/)
    end
  end

  context "when the viewer is signed in but not authorized to edit the effort" do
    before { login_as other_user, scope: :user }

    it "shows initials and obscures the age" do
      make_request

      expect(response.body).to include("K. M.")
      expect(response.body).not_to include("Keith")
      expect(response.body).not_to include("Metz")
      expect(response.body).not_to match(/Male, \d+/)
    end
  end

  context "when the viewer is an admin" do
    before { login_as admin_user, scope: :user }

    it "shows the real name and age" do
      make_request

      expect(response.body).to include("Keith Metz")
      expect(response.body).to include("Male, 42")
    end
  end
end
