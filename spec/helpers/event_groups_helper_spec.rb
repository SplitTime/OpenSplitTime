require "rails_helper"

RSpec.describe EventGroupsHelper do
  describe "#button_to_event_group_make_private" do
    subject(:html) { helper.button_to_event_group_make_private(view_object) }

    let(:event_group) { event_groups(:sum) }
    let(:view_object) do
      instance_double(EventGroupSetupPresenter,
                      organization: event_group.organization,
                      event_group: event_group,
                      event_group_name: event_group.name,
                      events: event_group.events.to_a)
    end

    context "when any event feeds projections" do
      it "includes the projections addendum before the confirmation question" do
        expect(html).to include("continue to feed pacing plans")
        expect(html).to include("Are you sure you want to proceed?")
      end
    end

    context "when no events feed projections" do
      before { event_group.events.each { |event| event.update_column(:use_for_projections, false) } }

      it "omits the projections addendum" do
        expect(html).not_to include("continue to feed pacing plans")
        expect(html).to include("Are you sure you want to proceed?")
      end
    end
  end
end
