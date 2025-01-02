require "rails_helper"

RSpec.describe SplitTimeQuery do
  include BitkeyDefinitions

  let(:lap_1) { 1 }

  describe ".typical_segment_time" do
    subject { SplitTimeQuery.typical_segment_time(segment, effort_ids) }
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

    context "for a course segment" do
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
  end
end
