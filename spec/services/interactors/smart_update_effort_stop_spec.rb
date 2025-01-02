require "rails_helper"

RSpec.describe ::Interactors::SmartUpdateEffortStop do
  subject { described_class.new(effort) }

  context "in a multi-lap event" do
    context "when the effort does not have a hanging split time" do
      let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }
      context "when the effort is not stopped" do
        it "sets the stop on the final finish time" do
          expect(effort.ordered_split_times.last).not_to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end

      context "when the effort is stopped" do
        before { effort.ordered_split_times.last.update(stopped_here: true) }
        it "sets the stop on the final finish time" do
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end
    end

    context "when the effort has a hanging split time" do
      let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }
      before do
        effort.ordered_split_times.last(2).each(&:destroy)
        effort.reload
      end

      context "when the effort is not stopped" do
        it "destroys the hanging split time and sets the stop on the final finish time" do
          expect(effort.ordered_split_times.last.split).not_to be_finish
          expect { subject.perform! }.to change { effort.split_times.count }.by(-1)
          expect(effort.ordered_split_times.last.split).to be_finish
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end

      context "when the effort is already stopped" do
        before { effort.ordered_split_times.last.update(stopped_here: true) }
        it "destroys the hanging split time and sets the stop on the final finish time" do
          expect(effort.ordered_split_times.last.split).not_to be_finish
          expect { subject.perform! }.to change { effort.split_times.count }.by(-1)
          expect(effort.ordered_split_times.last.split).to be_finish
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end
    end

    context "when the effort has a hanging split time and no final finish time" do
      let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }
      before do
        effort.ordered_split_times.last(2).each(&:destroy)
        effort.reload
        effort.ordered_split_times.last(2).first.destroy
        effort.reload
      end

      context "when the effort is not stopped" do
        it "destroys the hanging split time, creates a final finish time, and sets the stop on the final finish time" do
          existing_absolute_time = effort.ordered_split_times.last.absolute_time

          expect(effort.ordered_split_times.last.split).not_to be_finish
          expect(effort.ordered_split_times.last).not_to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last.split).to be_finish
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect(effort.ordered_split_times.last.absolute_time).to eq(existing_absolute_time)
        end
      end

      context "when the effort is already stopped" do
        before { ::Interactors::UpdateEffortsStop.perform!(effort) }
        it "destroys the hanging split time, creates a final finish time, and sets the stop on the final finish time" do
          existing_absolute_time = effort.ordered_split_times.last.absolute_time

          expect(effort.ordered_split_times.last.split).not_to be_finish
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last.split).to be_finish
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect(effort.ordered_split_times.last.absolute_time).to eq(existing_absolute_time)
        end
      end
    end

    context "when the effort has no split times" do
      let(:effort) { efforts(:rufa_2017_24h_not_started) }
      it "does nothing" do
        expect(effort.split_times).to be_empty
        subject.perform!
        expect(effort.split_times).to be_empty
      end
    end
  end

  context "in a single-lap event" do
    context "when the effort does not have a hanging split time" do
      let(:effort) { efforts(:hardrock_2016_rene_mclaughlin) }
      context "when the effort is not stopped" do
        it "sets the stop at the final time" do
          expect(effort.ordered_split_times.last).not_to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end

      context "when the effort is stopped" do
        before { effort.ordered_split_times.last.update(stopped_here: true) }
        it "does nothing" do
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end
    end

    context "when the effort has a hanging split time" do
      let(:effort) { efforts(:hardrock_2016_kory_kulas) }
      context "when the effort is not stopped" do
        it "destroys the hanging split time and sets the stop on the final finish time" do
          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::OUT_BITKEY)
          expect { subject.perform! }.to change { effort.split_times.count }.by(-1)
          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::IN_BITKEY)
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end

      context "when the effort is already stopped" do
        before { effort.ordered_split_times.last.update(stopped_here: true) }
        it "destroys the hanging split time and sets the stop on the final finish time" do
          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::OUT_BITKEY)
          expect { subject.perform! }.to change { effort.split_times.count }.by(-1)
          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::IN_BITKEY)
          expect(effort.ordered_split_times.last).to be_stopped_here
        end
      end
    end

    context "when the effort has a hanging split time and no final in time" do
      let(:effort) { efforts(:hardrock_2016_kory_kulas) }
      before do
        effort.ordered_split_times.last(2).first.destroy
        effort.reload
      end

      context "when the effort is not stopped" do
        it "destroys the hanging split time, creates a final in time, and sets the stop on the final in time" do
          existing_absolute_time = effort.ordered_split_times.last.absolute_time

          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::OUT_BITKEY)
          expect(effort.ordered_split_times.last).not_to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::IN_BITKEY)
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect(effort.ordered_split_times.last.absolute_time).to eq(existing_absolute_time)
        end
      end

      context "when the effort is already stopped" do
        before { effort.ordered_split_times.last.update(stopped_here: true) }
        it "destroys the hanging split time, creates a final finish time, and sets the stop on the final finish time" do
          existing_absolute_time = effort.ordered_split_times.last.absolute_time

          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::OUT_BITKEY)
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect { subject.perform! }.not_to change { effort.split_times.count }
          expect(effort.ordered_split_times.last.bitkey).to eq(::SubSplit::IN_BITKEY)
          expect(effort.ordered_split_times.last).to be_stopped_here
          expect(effort.ordered_split_times.last.absolute_time).to eq(existing_absolute_time)
        end
      end
    end
  end
end
