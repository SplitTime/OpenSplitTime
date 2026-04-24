require "rails_helper"

RSpec.describe "MyStuff dashboard" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:watched_person) { people(:not_started_utah_us) }

  before do
    watched_person.update!(obscure_name: true)
    login_as admin_user, scope: :user
  end

  after { Warden.test_reset! }

  describe "GET /my_stuff/live_updates" do
    it "shows initials for watched efforts when the person prefers an obscured name" do
      get my_stuff_live_updates_path

      expect(response.body).to include(watched_person.display_full_name)
      expect(response.body).not_to include(watched_person.full_name)
    end
  end

  describe "GET /my_stuff/interests" do
    it "shows initials for followed people when the person prefers an obscured name" do
      get my_stuff_interests_path

      expect(response.body).to include(watched_person.display_full_name)
      expect(response.body).not_to include(watched_person.full_name)
    end
  end
end
