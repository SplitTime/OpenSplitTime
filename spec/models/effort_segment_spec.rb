# frozen_string_literal: true

require "rails_helper"

RSpec.describe EffortSegment do
  let(:effort_1) { efforts(:hardrock_2015_tuan_jacobs) }
  let(:effort_2) { efforts(:hardrock_2015_erich_larson) }

  describe ".delete_all" do
    before { effort_1.set_effort_segments }

    it "deletes all effort_segments" do
      expect { EffortSegment.delete_all }.to change { EffortSegment.count }.from(91).to(0)
    end
  end

  describe ".delete_for_effort" do
    before do
      effort_1.set_effort_segments
      effort_2.set_effort_segments
    end

    it "deletes all effort_segments for the indicated effort" do
      expect { EffortSegment.delete_for_effort(effort_1) }.to change { EffortSegment.count }.from(182).to(91)
    end

    it "does not delete effort_segments for other efforts" do
      expect do
        EffortSegment.delete_for_effort(effort_1)
      end.not_to change { effort_2.effort_segments.count }
    end
  end

  describe ".delete_for_split_time" do
    let(:split_time_1) { effort_1.split_times.last }
    let(:split_time_2) { effort_2.split_times.last }

    before do
      effort_1.set_effort_segments
      effort_2.set_effort_segments
    end

    it "deletes all effort_segments for the split_time" do
      expect do
        EffortSegment.delete_for_split_time(split_time_1)
      end.to change { effort_1.effort_segments.count }.from(91).to(78)
    end

    it "does not delete effort_segments for other split_times" do
      expect do
        EffortSegment.delete_for_split_time(split_time_1)
      end.not_to change { effort_2.effort_segments.count }
    end
  end

  describe ".set_all" do
    it "sets effort_segments for all efforts" do
      expect { EffortSegment.set_all }.to change { EffortSegment.count }.from(0).to(4530)
    end
  end

  describe ".set_for_effort" do
    it "sets effort_segments for the indicated effort" do
      expect { EffortSegment.set_for_effort(effort_1) }.to change { effort_1.effort_segments.count }.from(0).to(91)
    end

    it "does not set effort_segments for other efforts" do
      expect { EffortSegment.set_for_effort(effort_1) }.not_to change { effort_2.effort_segments.count }
    end
  end

  describe ".set_for_split_time" do
    let(:split_time_1) { effort_1.split_times.last }
    let(:split_time_2) { effort_2.split_times.last }

    it "sets effort_segments for the split_time" do
      expect do
        EffortSegment.set_for_split_time(split_time_1)
      end.to change { effort_1.effort_segments.count }.from(0).to(13)
    end

    it "does not set effort_segments for other split_times" do
      expect do
        EffortSegment.set_for_split_time(split_time_1)
      end.not_to change { effort_2.effort_segments.count }
    end
  end
end
