require "rails_helper"

RSpec.describe VisitorIndexPresenter do
  subject(:presenter) { described_class.new(user) }

  let(:user) { users(:admin_user) }

  describe "#recent_event_groups" do
    let(:visible_event_group) { event_groups(:hardrock_2014) }
    let(:organization) { visible_event_group.organization }

    context "when the event group's organization is visible" do
      before { organization.update!(concealed: false) }

      it "includes the event group" do
        expect(presenter.recent_event_groups(50)).to include(visible_event_group)
      end
    end

    context "when the event group's organization is concealed" do
      before { organization.update!(concealed: true) }

      it "excludes the event group even if the event group itself is visible" do
        expect(visible_event_group.reload.concealed).to be(false)
        expect(presenter.recent_event_groups(50)).not_to include(visible_event_group)
      end
    end
  end
end
