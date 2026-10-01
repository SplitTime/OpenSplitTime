require "rails_helper"

RSpec.describe "Madmin index pages" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }

  before { login_as admin_user, scope: :user }
  after { Warden.test_reset! }

  madmin_index_routes = Rails.application.routes.routes.select do |route|
    route.defaults[:controller].to_s.start_with?("madmin/") && route.defaults[:action] == "index"
  end
  index_paths = madmin_index_routes.map { |route| route.path.spec.to_s.delete_suffix("(.:format)") }.sort

  index_paths.each do |path|
    it "renders #{path}" do
      get path

      expect(response).to have_http_status(:ok)
    end
  end

  it "renders association columns with display names rather than 'Model #N' labels" do
    get "/madmin/efforts"

    effort = efforts(:hardrock_2014_finished_first)
    expect(response.body).to include(effort.event.name)
    expect(response.body).not_to match(/Event #\d+/)
  end
end
