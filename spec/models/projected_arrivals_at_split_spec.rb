require "rails_helper"

RSpec.describe ProjectedArrivalsAtSplit do
  describe "name display methods" do
    subject do
      described_class.new(
        effort_id: 1,
        first_name: "Joan",
        last_name: "Smith",
        bib_number: 42,
        projected_time: Time.current,
        completed: false,
        stopped: false,
        event_short_name: "100k",
      )
    end

    describe "#full_name" do
      it { expect(subject.full_name).to eq("Joan Smith") }
    end

    # The privacy-bypass convention used elsewhere in the app (PersonalInfo,
    # FinishLineHelper) calls *_non_obscured methods to make it explicit that
    # we're rendering the underlying name regardless of obscure-name
    # preferences. The query result has no link to a Person, so these are
    # straight aliases.
    describe "#display_full_name_non_obscured" do
      it { expect(subject.display_full_name_non_obscured).to eq("Joan Smith") }
    end

    describe "#display_first_name_non_obscured" do
      it { expect(subject.display_first_name_non_obscured).to eq("Joan") }
    end

    describe "#display_last_name_non_obscured" do
      it { expect(subject.display_last_name_non_obscured).to eq("Smith") }
    end
  end
end
