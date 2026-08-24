require "rails_helper"

RSpec.describe SplitTimeQuery do
  include BitkeyDefinitions

  let(:lap_1) { 1 }

  describe ".set_efforts_elapsed_times" do
    let(:effort_with_start) { efforts(:hardrock_2015_tuan_jacobs) }
    let(:effort_without_start) { efforts(:hardrock_2014_without_start) }

    before do
      SplitTime.where(effort_id: [effort_with_start.id, effort_without_start.id]).update_all(elapsed_seconds: 123.0)
      execute_query
    end

    it "computes elapsed seconds from each effort's starting split time" do
      start_absolute_time = effort_with_start.starting_split_time.absolute_time
      effort_with_start.split_times.reload.each do |split_time|
        expect(split_time.elapsed_seconds).to eq(split_time.absolute_time - start_absolute_time)
      end
    end

    it "nullifies elapsed seconds for an effort having no starting split time" do
      expect(effort_without_start.split_times.reload.map(&:elapsed_seconds)).to all be_nil
    end

    def execute_query
      query = SplitTimeQuery.set_efforts_elapsed_times([effort_with_start.id, effort_without_start.id])
      ActiveRecord::Base.connection.execute(query)
    end
  end

  describe ".typical_segment_time" do
    subject { described_class.typical_segment_time(segment, effort_ids) }

    let(:count) { subject[:effort_count] }
    let(:time) { subject[:average] }

    let(:course) { courses(:hardrock_ccw) }
    let(:start_split) { course.splits.find_by(base_name: "Start") }
    let(:cunningham_split) { course.splits.find_by(base_name: "Cunningham") }
    let(:sherman_split) { course.splits.find_by(base_name: "Sherman") }
    let(:start) { TimePoint.new(lap_1, start_split.id, in_bitkey) }
    let(:cunningham_in) { TimePoint.new(lap_1, cunningham_split.id, in_bitkey) }
    let(:sherman_in) { TimePoint.new(lap_1, sherman_split.id, in_bitkey) }
    let(:sherman_out) { TimePoint.new(lap_1, sherman_split.id, out_bitkey) }
    let(:start_to_cunningham_in) { Segment.new(begin_point: start, end_point: cunningham_in) }
    let(:in_aid_sherman) { Segment.new(begin_point: sherman_in, end_point: sherman_out) }

    context "when effort_ids are not provided" do
      let(:segment) { start_to_cunningham_in }
      let(:effort_ids) { nil }

      it "returns average time and count" do
        expect(time).to be_within(100).of(9550)
      end
    end

    context "when effort_ids are provided" do
      let(:event) { events(:hardrock_2015) }
      let(:segment) { in_aid_sherman }
      let(:effort_ids) { event.efforts.order(:bib_number).ids.first(2) }

      it "limits the scope of the query" do
        expect(count).to eq(2)
        expect(time).to be_within(100).of(300)
      end
    end

    context "when the event is not used for projections" do
      before { events(:hardrock_2015).update_column(:use_for_projections, false) }

      context "when effort_ids are not provided" do
        let(:segment) { start_to_cunningham_in }
        let(:effort_ids) { nil }

        it "excludes the event's efforts from the pool" do
          expect(count).to eq(0)
          expect(time).to be_nil
        end
      end

      context "when effort_ids are provided" do
        let(:event) { events(:hardrock_2015) }
        let(:segment) { in_aid_sherman }
        let(:effort_ids) { event.efforts.order(:bib_number).ids.first(2) }

        it "excludes the event's efforts even when focused" do
          expect(count).to eq(0)
          expect(time).to be_nil
        end
      end
    end

    context "when a segment time is negative" do
      let(:segment) { in_aid_sherman }
      let(:effort_ids) { [effort.id] }
      let(:effort) { events(:hardrock_2015).efforts.order(:bib_number).first }

      before do
        in_time = effort.split_times.find_by(split: sherman_split, bitkey: in_bitkey)
        out_time = effort.split_times.find_by(split: sherman_split, bitkey: out_bitkey)
        out_time.update_column(:absolute_time, in_time.absolute_time - 1.minute)
      end

      it "excludes the negative pair from the pool" do
        expect(count).to eq(0)
        expect(time).to be_nil
      end
    end
  end
end
