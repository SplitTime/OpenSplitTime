require "rails_helper"

RSpec.describe PlanDisplay do
  subject { described_class.new(course: course, params: ActionController::Parameters.new(params)) }

  let(:course) { courses(:hardrock_ccw) }
  let(:params) { { expected_time: "38:00" } }

  context "when the course has visible events with relevant data" do
    it "returns no errors and builds projected split times" do
      expect(subject.error_messages).to be_empty
      expect(subject.ordered_split_times).to be_present
    end
  end

  context "when the course's only event is in a concealed event group but flagged for projections" do
    before { event_groups(:hardrock_2015).update_column(:concealed, true) }

    it "returns no errors and builds projected split times" do
      expect(subject.error_messages).to be_empty
      expect(subject.ordered_split_times).to be_present
    end
  end

  context "when no events on the course are flagged for projections" do
    before { course.events.each { |event| event.update_column(:use_for_projections, false) } }

    it "returns an error message" do
      expect(subject.error_messages).to include("No events on this course are available for planning.")
    end
  end
end
