require "rails_helper"

RSpec.describe "Live::GatingLocations::CrewPassages" do
  include Warden::Test::Helpers

  let(:event_group) { event_groups(:sum) }
  let(:gating_location) { gating_locations(:sum_bandera_gate) }
  let(:gle_100k) { gating_location_events(:sum_bandera_gate_100k) }
  let(:effort) { efforts(:sum_100k_drop_anvil) }
  let(:admin_user) { users(:admin_user) }
  let(:other_user) { users(:third_user) }

  after { Warden.test_reset! }

  before { allow(Projection).to receive(:execute_query).and_return([]) }

  def post_create
    post live_event_group_gating_location_crew_passages_path(event_group, gating_location),
         params: { effort_id: effort.id, gating_location_event_id: gle_100k.id }, as: :turbo_stream
  end

  describe "POST create" do
    context "when the user is not authorized" do
      before { login_as other_user, scope: :user }

      it "does not create a crew passage" do
        expect { post_create }.not_to change(CrewPassage, :count)
      end
    end

    context "when the user is authorized" do
      before { login_as admin_user, scope: :user }

      it "creates a crew passage for the effort at the gating location" do
        expect { post_create }.to change { gating_location.crew_passages.count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it "is idempotent" do
        post_create
        expect { post_create }.not_to change(CrewPassage, :count)
      end
    end
  end

  describe "DELETE destroy" do
    let!(:crew_passage) { gating_location.crew_passages.create!(effort: effort, passed_at: Time.current) }

    def delete_destroy
      delete live_event_group_gating_location_crew_passage_path(event_group, gating_location, crew_passage),
             params: { gating_location_event_id: gle_100k.id }, as: :turbo_stream
    end

    context "when the user is authorized" do
      before { login_as admin_user, scope: :user }

      it "destroys the crew passage" do
        expect { delete_destroy }.to change(CrewPassage, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user is not authorized" do
      before { login_as other_user, scope: :user }

      it "does not destroy the crew passage" do
        expect { delete_destroy }.not_to change(CrewPassage, :count)
      end
    end
  end
end
