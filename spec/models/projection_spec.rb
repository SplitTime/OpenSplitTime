require "rails_helper"

RSpec.describe ::Projection, type: :model do
  include BitkeyDefinitions

  describe ".execute_query" do
    subject do
      described_class.execute_query(
        split_time: split_time,
        starting_time_point: starting_time_point,
        subject_time_points: subject_time_points,
        ignore_times_beyond: ignore_times_beyond,
      )
    end

    let(:split_time) { effort.ordered_split_times.last }
    let(:effort) { efforts(:hardrock_2016_rene_mclaughlin) }
    let(:time_points) { effort.event.required_time_points }
    let(:starting_time_point) { time_points.first }
    let(:subject_time_points) { time_points.last(2) }
    let(:ignore_times_beyond) { nil }

    context "when given valid arguments" do
      it "returns rows containing projected ratios and seconds" do
        expect(subject.size).to eq(2)

        projection = subject.first
        expect(projection.time_point).to eq(subject_time_points.first)
        expect(projection.low_ratio).to be_within(0.05).of(0.30)
        expect(projection.average_ratio).to be_within(0.05).of(0.35)
        expect(projection.high_ratio).to be_within(0.05).of(0.40)
        expect(projection.low_seconds).to be_within(100).of(35_300)
        expect(projection.average_seconds).to be_within(100).of(39_700)
        expect(projection.high_seconds).to be_within(100).of(44_200)
      end

      context "when ignore_times_beyond is provided and no times are before" do
        let(:ignore_times_beyond) { "2000-01-01 05:00:00" }

        it "ignores all times" do
          expect(subject).to eq([])
        end
      end

      context "when ignore_times_beyond is provided and some times are before" do
        let(:ignore_times_beyond) { "2016-07-15 00:00:00" }

        it "ignores times beyond the provided time" do
          expect(subject.size).to eq(2)

          projection = subject.first
          expect(projection.time_point).to eq(subject_time_points.first)
          expect(projection.low_seconds).to be_within(100).of(35_500)
          expect(projection.average_seconds).to be_within(100).of(40_100)
          expect(projection.high_seconds).to be_within(100).of(44_700)
        end
      end

      context "when ignore_times_beyond predates newer events on the same course" do
        let(:effort) { efforts(:hardrock_2014_finished_without_stop) }
        let(:split_time) { effort.ordered_split_times[5] }
        let(:subject_time_points) { [time_points[6]] }
        let(:ignore_times_beyond) { split_time.absolute_time }

        before do
          4.times do |i|
            create(
              :event,
              :with_short_name,
              course: courses(:hardrock_cw),
              event_group: event_groups(:hardrock_2016),
              scheduled_start_time: Time.zone.parse("#{2017 + i}-07-14 12:00:00"),
            )
          end
        end

        it "draws its sample only from events available at that time" do
          expect(subject).to be_present

          projection = subject.first
          expect(projection.time_point).to eq(subject_time_points.first)
          expect(projection.effort_years).to eq([2014])
          expect(projection.effort_count).to be_positive
        end
      end
    end

    context "when given a starting split time" do
      let(:split_time) { effort.ordered_split_times.first }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when given no subject time points" do
      let(:subject_time_points) { [] }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end

  describe "#time_point" do
    subject { described_class.new(lap: lap, split_id: split_id, sub_split_bitkey: bitkey) }

    let(:lap) { 1 }
    let(:split_id) { 2 }
    let(:bitkey) { out_bitkey }
    it "returns a TimePoint with expected values" do
      expect(subject.time_point).to eq(::TimePoint.new(lap, split_id, bitkey))
    end
  end
end
