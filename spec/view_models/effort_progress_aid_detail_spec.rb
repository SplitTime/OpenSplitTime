require "rails_helper"

RSpec.describe EffortProgressAidDetail do
  subject do
    described_class.new(effort: effort,
                        event_framework: event_framework,
                        lap: lap,
                        effort_split_times: effort_split_times,
                        times_container: times_container)
  end

  let(:effort) { Effort.where(id: efforts(:hardrock_2014_progress_sherman).id).finish_info_subquery.first }
  let(:event_framework) { AidStationDetail.new(event: event, parameterized_split_name: split.parameterized_base_name) }
  let(:lap) { 1 }
  let(:effort_split_times) { effort&.ordered_split_times }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
  let(:event) { events(:hardrock_2014) }
  let(:split) { splits(:hardrock_cw_cunningham) }

  describe "#initialize" do
    context "with all required arguments" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "when no effort is given" do
      let(:effort) { nil }
      it { expect { subject }.to raise_error(/must include effort/) }
    end

    context "when no event_framework is given" do
      let(:event_framework) { nil }
      it { expect { subject }.to raise_error(/must include event_framework/) }
    end

    context "when no lap is given" do
      let(:lap) { nil }
      it { expect { subject }.to raise_error(/must include lap/) }
    end

    context "when no effort_split_times is given" do
      let(:effort_split_times) { nil }
      it { expect { subject }.to raise_error(/must include effort_split_times/) }
    end

    context "when no times_container is given" do
      let(:times_container) { nil }
      it { expect { subject }.to raise_error(/must include times_container/) }
    end
  end

  describe "#expected_here_info" do
    let(:result) { subject.expected_here_info }

    it "returns an EffortSplitData object" do
      expect(result).to be_a(EffortSplitData)
    end

    it "includes the effort slug" do
      expect(result.effort_slug).to eq(effort.slug)
    end
  end

  describe "#recorded_here_info" do
    let(:result) { subject.recorded_here_info }

    it "returns an EffortSplitData object" do
      expect(result).to be_a(EffortSplitData)
    end
  end

  describe "#prior_to_here_info" do
    let(:result) { subject.prior_to_here_info }

    it "returns an EffortSplitData object" do
      expect(result).to be_a(EffortSplitData)
    end
  end

  describe "#after_here_info" do
    let(:result) { subject.after_here_info }

    it "returns an EffortSplitData object" do
      expect(result).to be_a(EffortSplitData)
    end
  end
end
