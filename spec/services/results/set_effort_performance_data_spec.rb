# frozen_string_literal: true

require "rails_helper"

RSpec.describe Results::SetEffortPerformanceData do
  subject { described_class.new(effort_ids) }

  describe "#perform!" do
    context "for a single effort" do
      let(:effort_ids) { [effort.id] }

      before { clear_performance_attributes(effort) }

      context "for a single lap event" do
        context "when the effort is not started" do
          let(:effort) { efforts(:hardrock_2014_not_started) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to be_nil
            expect(effort.final_split_time_id).to be_nil
            expect(effort.started).to eq(false)
            expect(effort.beyond_start).to eq(false)
            expect(effort.stopped).to eq(false)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(false)
          end
        end

        context "when the effort is started but is not beyond start" do
          let(:effort) { efforts(:hardrock_2016_start_only) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to be_nil
            expect(effort.final_split_time_id).to eq(effort.ordered_split_times.first.id)
            expect(effort.started).to eq(true)
            expect(effort.beyond_start).to eq(false)
            expect(effort.stopped).to eq(false)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(false)
          end
        end

        context "when the effort is in progress beyond start" do
          let(:effort) { efforts(:hardrock_2014_progress_sherman) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to be_nil
            expect(effort.final_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.started).to eq(true)
            expect(effort.beyond_start).to eq(true)
            expect(effort.stopped).to eq(false)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(false)
          end
        end

        context "when the effort is finished" do
          let(:effort) { efforts(:hardrock_2014_finished_first) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.final_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.started).to eq(true)
            expect(effort.beyond_start).to eq(true)
            expect(effort.stopped).to eq(true)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(true)
          end
        end

        context "when the effort is dropped" do
          let(:effort) { efforts(:hardrock_2014_drop_ouray) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.final_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.started).to eq(true)
            expect(effort.beyond_start).to eq(true)
            expect(effort.stopped).to eq(true)
            expect(effort.dropped).to eq(true)
            expect(effort.finished).to eq(false)
          end
        end
      end

      context "for a multi-lap event" do
        context "when the effort is not started" do
          let(:effort) { efforts(:rufa_2016_not_started) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to be_nil
            expect(effort.final_split_time_id).to be_nil
            expect(effort.started).to eq(false)
            expect(effort.beyond_start).to eq(false)
            expect(effort.stopped).to eq(false)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(false)
          end
        end

        context "when the effort is started but is not beyond start" do
          let(:effort) { efforts(:rufa_2017_12h_start_only) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to be_nil
            expect(effort.final_split_time_id).to eq(effort.ordered_split_times.first.id)
            expect(effort.started).to eq(true)
            expect(effort.beyond_start).to eq(false)
            expect(effort.stopped).to eq(false)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(false)
          end
        end

        context "when the effort is in progress beyond start" do
          let(:effort) { efforts(:rufa_2017_12h_progress_lap5_partial) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to be_nil
            expect(effort.final_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.started).to eq(true)
            expect(effort.beyond_start).to eq(true)
            expect(effort.stopped).to eq(false)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(false)
          end
        end

        context "when the effort is finished" do
          let(:effort) { efforts(:rufa_2017_12h_finished_first) }

          it "sets attributes as expected" do
            expect(effort.overall_performance).to be_nil
            subject.perform!
            effort.reload
            expect(effort.overall_performance).to be_present
            expect(effort.stopped_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.final_split_time_id).to eq(effort.ordered_split_times.last.id)
            expect(effort.started).to eq(true)
            expect(effort.beyond_start).to eq(true)
            expect(effort.stopped).to eq(true)
            expect(effort.dropped).to eq(false)
            expect(effort.finished).to eq(true)
          end
        end
      end
    end

    context "for multiple efforts" do
      let(:effort_ids) { [effort_1.id, effort_2.id] }
      let(:effort_1) { efforts(:rufa_2016_not_started) }
      let(:effort_2) { efforts(:rufa_2017_12h_finished_first) }

      before do
        [effort_1, effort_2].each(&method(:clear_performance_attributes))
      end
      
      it "sets attributes for the second effort as expected" do
        expect(effort_1.overall_performance).to be_nil
        expect(effort_2.overall_performance).to be_nil

        subject.perform!

        effort_1.reload
        effort_2.reload

        expect(effort_1.overall_performance).to be_present
        expect(effort_1.stopped_split_time_id).to be_nil
        expect(effort_1.final_split_time_id).to be_nil
        expect(effort_1.started).to eq(false)
        expect(effort_1.beyond_start).to eq(false)
        expect(effort_1.stopped).to eq(false)
        expect(effort_1.dropped).to eq(false)
        expect(effort_1.finished).to eq(false)

        expect(effort_2.overall_performance).to be_present
        expect(effort_2.stopped_split_time_id).to eq(effort_2.ordered_split_times.last.id)
        expect(effort_2.final_split_time_id).to eq(effort_2.ordered_split_times.last.id)
        expect(effort_2.started).to eq(true)
        expect(effort_2.beyond_start).to eq(true)
        expect(effort_2.stopped).to eq(true)
        expect(effort_2.dropped).to eq(false)
        expect(effort_2.finished).to eq(true)
      end
    end

    context "when setting an entire event" do
      let(:event) { events(:hardrock_2014) }
      let(:effort_ids) { event.efforts.ids}

      before do
        event.efforts.each { |effort| clear_performance_attributes(effort) }
      end

      it "sets overall performance such that efforts are correctly ranked" do
        subject.perform!
        ranked_bib_numbers = event.efforts.order(overall_performance: :desc).pluck(:bib_number)
        expect(ranked_bib_numbers).to eq([148, 4, 147, 104, 123, 159, 121, 37, 41, 36, 120, 32, 158, 145, 166, 187, 119, 142, 115])
      end
    end
  end

  def clear_performance_attributes(effort)
    effort.update_columns(
      overall_performance: nil,
      stopped_split_time_id: nil,
      final_split_time_id: nil,
      started: nil,
      beyond_start: nil,
      stopped: nil,
      dropped: nil,
      finished: nil,
      )
  end
end
