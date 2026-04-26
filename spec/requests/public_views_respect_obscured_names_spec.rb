require "rails_helper"

RSpec.describe "Public views respect obscure_name and hide_age" do
  let(:event) { events(:hardrock_2014) }
  let(:event_group) { event.event_group }
  let(:organization) { event_group.organization }
  let(:effort) { efforts(:hardrock_2014_finished_first) }
  let(:person) { effort.person }

  before do
    effort.update!(first_name: "Distinct", last_name: "Surname", age: 99)
    person.update!(first_name: "Distinct", last_name: "Surname", obscure_name: true, hide_age: true)
  end

  shared_examples "obscures the name and age" do
    it "renders initials and never the full name or real age" do
      make_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("D. S.")
      expect(response.body).not_to include("Distinct")
      expect(response.body).not_to include("Surname")
      expect(response.body).not_to match(/Male, 99/)
    end
  end

  describe "GET /events/:id/spread" do
    subject(:make_request) { get spread_event_path(event.reload) }

    it_behaves_like "obscures the name and age"
  end

  describe "GET /events/:id/finish_history" do
    subject(:make_request) { get finish_history_event_path(event.reload) }

    it_behaves_like "obscures the name and age"
  end

  describe "GET /events/:id/podium" do
    subject(:make_request) { get podium_event_path(event.reload) }

    it_behaves_like "obscures the name and age"
  end

  describe "GET /efforts/:id" do
    subject(:make_request) { get effort_path(effort.reload) }

    it_behaves_like "obscures the name and age"
  end

  describe "GET /efforts/:id/place" do
    subject(:make_request) { get place_effort_path(effort.reload) }

    it_behaves_like "obscures the name and age"
  end

  describe "GET /efforts/:id/analyze" do
    subject(:make_request) { get analyze_effort_path(effort.reload) }

    it_behaves_like "obscures the name and age"
  end

  describe "GET /efforts/:id/projections" do
    subject(:make_request) { get projections_effort_path(effort.reload) }

    it_behaves_like "obscures the name and age"
  end

  describe "GET /people/:id" do
    subject(:make_request) { get person_path(person.reload) }

    it_behaves_like "obscures the name and age"
  end
end
