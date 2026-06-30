require "rails_helper"

RSpec.describe "Efforts crew access" do
  let(:gated_effort) { efforts(:sum_100k_drop_anvil) }
  let(:ungated_effort) { efforts(:ggd30_50k_bad_finish) }

  before { allow(Projection).to receive(:execute_query).and_return([]) }

  describe "GET crew_access" do
    it "is public and shows the runner's gating locations" do
      get crew_access_effort_path(gated_effort)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Earliest crew release")
    end

    context "when the event group is concealed" do
      before { gated_effort.event_group.update!(concealed: true) }

      it "is not accessible to an anonymous user" do
        expect { get crew_access_effort_path(gated_effort) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "the Crew Access tab on the effort show page" do
    it "appears for a gated effort" do
      get effort_path(gated_effort)

      expect(response.body).to include(crew_access_effort_path(gated_effort))
    end

    it "is absent for an ungated effort" do
      get effort_path(ungated_effort)

      expect(response.body).not_to include(crew_access_effort_path(ungated_effort))
    end
  end
end
