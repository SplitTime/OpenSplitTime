require "rails_helper"

RSpec.describe "PeopleController" do
  include Warden::Test::Helpers

  after { Warden.test_reset! }

  describe "DELETE /people/:id" do
    let(:admin) { users(:admin_user) }
    let(:person) { people(:alfreda_cruickshank) }

    before { login_as admin, scope: :user }

    it "deletes the person and redirects to the index with a 303 so Turbo follows with a GET" do
      delete person_path(person)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(people_path)
      expect(Person.exists?(person.id)).to be(false)
    end
  end
end
