require "rails_helper"

RSpec.describe "EventGroups admin views reveal obscured names and ages" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:event_group) { event_groups(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_bad_status) }

  before do
    effort.person.update!(first_name: "Bad", last_name: "Status", obscure_name: true, hide_age: true)
    login_as admin_user, scope: :user
  end

  after { Warden.test_reset! }

  describe "GET /event_groups/:id/drop_list" do
    it "shows the full name and real age instead of initials" do
      get drop_list_event_group_path(event_group)

      expect(response.body).to include("Bad Status")
      expect(response.body).not_to match(/\bB\. S\.\b/)
      expect(response.body).to include("Male, #{effort.age}")
    end
  end

  describe "GET /event_groups/:id/roster" do
    it "shows the full name and real age instead of initials" do
      get roster_event_group_path(event_group)

      expect(response.body).to include("Bad Status")
      expect(response.body).to include("Male, #{effort.age}")
    end
  end

  describe "GET /event_groups/:id/entrants (setup)" do
    it "shows the full name and real age instead of initials" do
      get entrants_event_group_path(event_group)

      expect(response.body).to include("Bad Status")
      expect(response.body).to include("Male, #{effort.age}")
    end
  end

  describe "GET /event_groups/:id/setup_summary" do
    it "shows the full name and real age instead of initials" do
      get setup_summary_event_group_path(event_group)

      expect(response.body).to include("Bad Status")
      expect(response.body).to include("Male, #{effort.age}")
    end
  end
end
