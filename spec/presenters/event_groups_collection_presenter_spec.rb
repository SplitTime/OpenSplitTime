require "rails_helper"

RSpec.describe EventGroupsCollectionPresenter do
  subject { described_class.new(view_context) }

  let(:view_context) do
    double("view_context", # rubocop:disable RSpec/VerifiedDoubles
           current_user: current_user,
           params: prepared_params,
           request: request_double,
           url_for: nil)
  end

  let(:request_double) { double("request", params: prepared_params) } # rubocop:disable RSpec/VerifiedDoubles
  let(:prepared_params) { PreparedParams.new(ActionController::Parameters.new(params_hash), permitted, permitted_query) }
  let(:params_hash) { {} }
  let(:permitted) { [:search] }
  let(:permitted_query) { [:search] }

  let(:current_user) { users(:admin_user) }

  let!(:visible_event_group) { create(:event_group, concealed: false) }
  let!(:concealed_event_group) { create(:event_group, concealed: true) }

  before do
    create(:event, event_group: visible_event_group)
    create(:event, event_group: concealed_event_group)
  end

  describe "#event_groups" do
    context "when the user is an admin" do
      let(:current_user) { users(:admin_user) }

      it "returns all event groups" do
        expect(subject.event_groups).to include(visible_event_group, concealed_event_group)
      end
    end

    context "when the user is not logged in" do
      let(:current_user) { nil }

      it "returns only visible event groups" do
        expect(subject.event_groups).to include(visible_event_group)
        expect(subject.event_groups).not_to include(concealed_event_group)
      end
    end

    context "when a search param is provided" do
      let(:params_hash) { { filter: { search: visible_event_group.name } } }

      it "filters event groups to those matching the search text" do
        result = subject.event_groups
        expect(result).to include(visible_event_group)
      end
    end

    context "when a search param does not match any event group" do
      let(:params_hash) { { filter: { search: "zzz_nonexistent_zzz" } } }

      it "returns no event groups" do
        expect(subject.event_groups).to be_empty
      end
    end

    it "preloads events" do
      event_group = subject.event_groups.find { |eg| eg.id == visible_event_group.id }
      expect(event_group.association(:events)).to be_loaded
    end
  end

  describe "#event_groups_count" do
    let(:current_user) { nil }

    it "returns the count of matching event groups" do
      expect(subject.event_groups_count).to be >= 1
    end
  end

  describe "#show_visibility_columns?" do
    context "when the user is an admin" do
      let(:current_user) { users(:admin_user) }

      it "returns true" do
        expect(subject.show_visibility_columns?).to eq(true)
      end
    end

    context "when the user has stewardships" do
      let(:current_user) { users(:third_user) }

      before { Stewardship.create!(user: current_user, organization: visible_event_group.organization) }

      it "returns true" do
        expect(subject.show_visibility_columns?).to eq(true)
      end
    end

    context "when the user has no stewardships and is not an admin" do
      let(:current_user) { users(:third_user) }

      it "returns false" do
        expect(subject.show_visibility_columns?).to eq(false)
      end
    end

    context "when the user is nil" do
      let(:current_user) { nil }

      it "returns false" do
        expect(subject.show_visibility_columns?).to eq(false)
      end
    end
  end

  describe "#next_page_url" do
    context "when there is no next page" do
      it "returns nil" do
        expect(subject.next_page_url).to be_nil
      end
    end
  end
end
