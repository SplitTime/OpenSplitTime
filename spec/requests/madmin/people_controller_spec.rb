require "rails_helper"

RSpec.describe "Madmin::PeopleController" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:person) { people(:alfreda_cruickshank) }

  before { login_as admin_user, scope: :user }
  after { Warden.test_reset! }

  describe "GET /madmin/people/:id/edit" do
    it "renders the edit form without inputs for attributes the model no longer has" do
      get "/madmin/people/#{person.slug}/edit"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("person[topic_resource_key]")
      expect(response.body).not_to include("person[subscriptions]")
      expect(response.body).not_to include("person[followers]")
    end
  end

  describe "PATCH /madmin/people/:id" do
    it "updates the person and redirects to the show page, ignoring stale form keys" do
      # Browsers with a cached edit form still post the dropped attribute; it must be filtered, not assigned.
      patch "/madmin/people/#{person.slug}", params: { person: { city: "Leadville", topic_resource_key: "" } }

      expect(response).to redirect_to("/madmin/people/#{person.slug}")
      expect(person.reload.city).to eq("Leadville")
    end
  end
end
