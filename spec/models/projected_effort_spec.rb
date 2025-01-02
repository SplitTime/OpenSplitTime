require "rails_helper"

RSpec.describe ProjectedEffort, type: :model do
  subject do
    described_class.new(
      event: event,
      start_time: start_time,
      baseline_split_time: baseline_split_time,
      projected_time_points: projected_time_points,
    )
  end

  describe "#ordered_split_times" do
    context "when projecting times for an effort in progress" do
      let(:effort) { efforts(:hardrock_2016_shad_hirthe) }
      let(:event) { events(:hardrock_2016) }
      let(:start_time) { event.scheduled_start_time }
      let(:projected_time_points) { event.required_time_points.last(3) }
      let(:baseline_split_time) { effort.ordered_split_times.last }

      let(:expected_absolute_times) do
        [
          "2016-07-16 21:03:42 UTC",
          "2016-07-16 21:15:31 UTC",
          "2016-07-17 01:07:03 UTC",
        ]
      end

      it "creates split_times for each requested time point" do
        expect(subject.ordered_split_times.size).to eq(3)
        expect(subject.ordered_split_times).to all be_a(::SplitTime)
        expect(subject.ordered_split_times.map(&:time_point)).to eq(projected_time_points)
        expect(subject.ordered_split_times.map(&:absolute_time)).to eq(expected_absolute_times)
      end
    end

    context "when creating times for a typical effort" do
      let(:event) { events(:hardrock_2016) }
      let(:course) { event.course }
      let(:start_time) { event.scheduled_start_time }
      let(:projected_time_points) { event.required_time_points }
      let(:baseline_split_time) do
        ::SplitTime.new(
          split: course.finish_split,
          bitkey: ::SubSplit::IN_BITKEY,
          lap: 1,
          absolute_time: start_time + 40.hours,
          designated_seconds_from_start: 40.hours / 1.second,
        )
      end

      let(:expected_absolute_times) do
        [
          "2016-07-15 12:00:00 UTC",
          "2016-07-15 20:50:19 UTC",
          "2016-07-15 21:06:08 UTC",
          "2016-07-16 02:04:07 UTC",
          "2016-07-16 02:25:12 UTC",
          "2016-07-16 08:22:52 UTC",
          "2016-07-16 08:47:19 UTC",
          "2016-07-16 14:31:26 UTC",
          "2016-07-16 14:52:53 UTC",
          "2016-07-16 23:36:38 UTC",
          "2016-07-16 23:49:31 UTC",
          "2016-07-17 04:00:00 UTC",
        ]
      end

      it "creates split_times for each requested time point" do
        expect(subject.ordered_split_times.size).to eq(12)
        expect(subject.ordered_split_times).to all be_a(::SplitTime)
        expect(subject.ordered_split_times.map(&:time_point)).to eq(projected_time_points)
        expect(subject.ordered_split_times.map(&:absolute_time)).to eq(expected_absolute_times)
      end
    end
  end
end
