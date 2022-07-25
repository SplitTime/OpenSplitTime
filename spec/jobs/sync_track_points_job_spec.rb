# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncTrackPointsJob do
  subject { described_class.new(course) }
  let(:course) { build(:course) }

  context "when no gpx file is attached" do
    it "sets track_points to an empty array" do
      subject.perform_now
      expect(course.track_points).to eq([])
    end
  end

  context "when a gpx file is attached" do
    let(:course) { create(:course, :with_gpx) }

    it "sets track_points to an array of lat/lon points" do
      expect(course.track_points).to be_nil
      subject.perform_now
      expect(course.track_points.size).to eq(113)
      expect(course.track_points.first).to eq({ "lat" => 39.6270910, "lon" => -104.9042260 })
      expect(course.track_points.last).to eq({ "lat" => 39.6238040, "lon" => -104.8933630 })
    end
  end
end
