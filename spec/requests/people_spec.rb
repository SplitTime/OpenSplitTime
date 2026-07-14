require "rails_helper"

RSpec.describe "PeopleController" do
  include Warden::Test::Helpers

  # Turbo submits mutations (and follows their redirects) with this Accept header.
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" } }

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

    it "follows the delete redirect to a full HTML page, not a turbo stream" do
      delete person_path(person), headers: turbo_headers
      expect(response).to have_http_status(:see_other)

      # The redirected GET inherits the turbo-stream Accept header; it must still render full HTML
      # so Turbo performs a real navigation to the index rather than applying a stream in place.
      get response.location, headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
    end
  end

  describe "GET /people" do
    it "serves the paginated Show More request as a turbo stream" do
      get people_path(page: 2), headers: turbo_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
