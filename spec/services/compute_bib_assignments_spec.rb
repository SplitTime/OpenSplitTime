require "rails_helper"

RSpec.describe ComputeBibAssignments do
  subject { described_class.new(event, strategy) }

  describe "#perform" do
    let(:result) { subject.perform }

    context "hardrock strategy" do
      let(:strategy) { :hardrock }
      let(:event) { events(:hardrock_2016) }
      let(:effort_1) { event.efforts.ranked_order.first }
      let(:effort_2) { event.efforts.ranked_order.second }
      let(:effort_3) { event.efforts.ranked_order.third }
      let(:effort_4) { event.efforts.ranked_order.fourth }

      context "when no entrants finished the prior year" do
        before { event.efforts.ranked_order.last(15).each(&:destroy) }

        let(:expected_result) do
          {
            effort_1.id => 102,
            effort_2.id => 100,
            effort_3.id => 101,
            effort_4.id => 103
          }
        end

        it "computes bibs alphabetically starting at 100" do
          expect(result).to eq(expected_result)
        end
      end

      context "when some entrants finished the prior year" do
        let(:prior_event) { events(:hardrock_2015) }
        let(:prior_event_effort_1) { prior_event.efforts.ranked_order.first }
        let(:prior_event_effort_2) { prior_event.efforts.ranked_order.second }

        before do
          event.efforts.ranked_order.last(15).each(&:destroy)
          effort_1.update(person_id: prior_event_effort_1.person_id)
          effort_2.update(person_id: prior_event_effort_2.person_id)
        end

        let(:expected_result) do
          {
            effort_1.id => 1,
            effort_2.id => 2,
            effort_3.id => 100,
            effort_4.id => 101,
          }
        end

        it "computes bibs of prior year finishers starting at 1 and other bibs alphabetically starting at 100" do
          expect(result).to eq(expected_result)
        end
      end

      context "when an entrant has a hardcoded bib number" do
        let(:prior_event) { events(:hardrock_2015) }

        before do
          event.efforts.ranked_order.last(15).each(&:destroy)
          effort_1.update(bib_number: "85", bib_number_hardcoded: true)
        end

        let(:expected_result) do
          {
            effort_2.id => 100,
            effort_3.id => 101,
            effort_4.id => 102,
          }
        end

        it "ignores hardcoded bib numbers" do
          expect(result).to eq(expected_result)
        end
      end
    end
  end
end
