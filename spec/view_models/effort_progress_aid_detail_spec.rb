require "rails_helper"

RSpec.describe EffortProgressAidDetail do
  let(:event) { events(:hardrock_2014) }
  let(:effort) { Effort.where(id: efforts(:hardrock_2014_progress_sherman).id).finish_info_subquery.first }
  let(:split) { splits(:hardrock_cw_cunningham) }
  let(:effort_split_times) { effort.ordered_split_times }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
  let(:event_framework) { AidStationDetail.new(event: event, parameterized_split_name: split.parameterized_base_name) }

  subject do
    EffortProgressAidDetail.new(effort: effort,
                                event_framework: event_framework,
                                lap: 1,
                                effort_split_times: effort_split_times,
                                times_container: times_container)
  end

  describe "#initialize" do
    context "with all required arguments" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "if no effort is given" do
      it "raises an ArgumentError" do
        expect {
          EffortProgressAidDetail.new(effort: nil,
                                      event_framework: event_framework,
                                      lap: 1,
                                      effort_split_times: [],
                                      times_container: times_container)
        }.to raise_error(/must include effort/)
      end
    end

    context "if no event_framework is given" do
      it "raises an ArgumentError" do
        expect {
          EffortProgressAidDetail.new(effort: effort,
                                      event_framework: nil,
                                      lap: 1,
                                      effort_split_times: effort_split_times,
                                      times_container: times_container)
        }.to raise_error(/must include event_framework/)
      end
    end

    context "if no lap is given" do
      it "raises an ArgumentError" do
        expect {
          EffortProgressAidDetail.new(effort: effort,
                                      event_framework: event_framework,
                                      lap: nil,
                                      effort_split_times: effort_split_times,
                                      times_container: times_container)
        }.to raise_error(/must include lap/)
      end
    end

    context "if no effort_split_times is given" do
      it "raises an ArgumentError" do
        expect {
          EffortProgressAidDetail.new(effort: effort,
                                      event_framework: event_framework,
                                      lap: 1,
                                      effort_split_times: nil,
                                      times_container: times_container)
        }.to raise_error(/must include effort_split_times/)
      end
    end

    context "if no times_container is given" do
      it "raises an ArgumentError" do
        expect {
          EffortProgressAidDetail.new(effort: effort,
                                      event_framework: event_framework,
                                      lap: 1,
                                      effort_split_times: effort_split_times,
                                      times_container: nil)
        }.to raise_error(/must include times_container/)
      end
    end
  end

  describe "#expected_here_info" do
    it "returns an EffortSplitData object" do
      expect(subject.expected_here_info).to be_a(EffortSplitData)
    end

    it "includes the effort slug" do
      expect(subject.expected_here_info.effort_slug).to eq(effort.slug)
    end
  end

  describe "#recorded_here_info" do
    it "returns an EffortSplitData object" do
      expect(subject.recorded_here_info).to be_a(EffortSplitData)
    end
  end

  describe "#prior_to_here_info" do
    it "returns an EffortSplitData object" do
      expect(subject.prior_to_here_info).to be_a(EffortSplitData)
    end
  end

  describe "#after_here_info" do
    it "returns an EffortSplitData object" do
      expect(subject.after_here_info).to be_a(EffortSplitData)
    end
  end
end
