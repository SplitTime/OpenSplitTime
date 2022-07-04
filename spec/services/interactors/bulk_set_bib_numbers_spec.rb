# frozen_string_literal: true

require "rails_helper"

RSpec.describe Interactors::BulkSetBibNumbers do
  subject { described_class.new(event_group, bib_assignments) }
  let(:event_group) { event_groups(:hardrock_2016) }
  let(:event) { event_group.first_event }
  let(:effort_1) { event.efforts.ranked_order.first }
  let(:effort_2) { event.efforts.ranked_order.second }
  let(:bib_assignments) do
    {
      effort_1.id => "22",
      effort_2.id => "23",
    }
  end

  describe "#perform!" do
    let(:result) { subject.perform! }
    context "when assignments are given and no duplicates exist" do
      it "sets bib numbers as directed" do
        result
        expect(effort_1.reload.bib_number).to eq(22)
        expect(effort_2.reload.bib_number).to eq(23)
      end
    end

    context "when a provided bib number is a duplicate" do
      let!(:existing_effort) { efforts(:hardrock_2016_shad_hirthe) }
      let!(:existing_effort_bib_number) { existing_effort.bib_number.to_s }

      let(:bib_assignments) do
        {
          effort_1.id => "22",
          effort_2.id => existing_effort_bib_number,
        }
      end

      it "sets bib numbers as directed and blanks out the duplicate" do
        result
        expect(effort_1.reload.bib_number).to eq(22)
        expect(effort_2.reload.bib_number).to eq(existing_effort_bib_number.to_i)
        expect(existing_effort.reload.bib_number).to be_nil
      end
    end

    context "when the assignments contain an internal duplicate" do
      let(:bib_assignments) do
        {
          effort_1.id => "22",
          effort_2.id => "22",
        }
      end

      it "sets the second and blanks out the first" do
        result
        expect(effort_1.reload.bib_number).to be_nil
        expect(effort_2.reload.bib_number).to eq(22)
      end
    end
  end
end
