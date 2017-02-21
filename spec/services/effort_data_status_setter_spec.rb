require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortDataStatusSetter do
  before do
    FactoryGirl.reload
  end

  let(:split_times_100) { FactoryGirl.build_stubbed_list(:split_times_hardrock_45, 10, effort_id: 100) }
  let(:split_times_104) { FactoryGirl.build_stubbed_list(:split_times_hardrock_36, 10, effort_id: 104) }
  let(:split_times_105) { FactoryGirl.build_stubbed_list(:split_times_hardrock_35, 10, effort_id: 105) }
  let(:split_times_109) { FactoryGirl.build_stubbed_list(:split_times_hardrock_25, 10, effort_id: 109) }
  let(:test_splits) { FactoryGirl.build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }
  let(:test_effort) { FactoryGirl.build_stubbed(:effort, event_id: 50) }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  describe '#initialize' do
    it 'initializes with an effort and a times_container in an args hash' do
      effort = FactoryGirl.build_stubbed(:effort)
      times_container = SegmentTimesContainer.new(calc_model: :terrain)
      expect { EffortDataStatusSetter.new(effort: effort,
                                          times_container: times_container) }.not_to raise_error
    end

    it 'raises an ArgumentError if no effort is given' do
      times_container = SegmentTimesContainer.new(calc_model: :terrain)
      expect { EffortDataStatusSetter.new(times_container: times_container) }
          .to raise_error(/must include effort/)
    end
  end

  describe '#set_data_status' do

    context 'for an effort that has not yet started' do
      it 'sets effort data_status to good and does not attempt to change split_times' do
        effort = Effort.new(first_name: 'John', last_name: 'Doe', gender: 'male', data_status: nil)
        times_container = SegmentTimesContainer.new(calc_model: :terrain)
        allow(effort).to receive(:lap_splits).and_return([])
        setter = EffortDataStatusSetter.new(effort: effort, times_container: times_container)
        setter.set_data_status
        expect(setter.changed_split_times).to eq([])
        expect(setter.changed_efforts).to eq([effort])
        expect(effort.data_status).to eq('good')
      end
    end

    context 'for an effort partially underway or completed in a single-lap event' do
      let(:test_event) { FactoryGirl.build_stubbed(:event, id: 50, laps_required: 1) }
      let(:test_course) { FactoryGirl.build_stubbed(:course) }

      it 'sets data_status of all split_times and effort to "good" when split_times fall within expected ranges' do
        n = 10
        split_times = split_times_104.first(n)
        split_times_status = ['good'] * n
        effort_status = 'good'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of starting split_time to "bad" if time_from_start is non-zero' do
        n = 5
        split_times = split_times_104.first(n)
        split_times[0].time_from_start = 100
        split_times_status = %w(bad good good good good)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of intermediate split_times to "bad" if time_from_start is less than earlier time_from_start' do
        n = 5
        split_times = split_times_104.first(n)
        split_times[2].time_from_start = split_times[1].time_from_start - 60
        split_times[4].time_from_start = split_times[3].time_from_start - 60
        split_times_status = %w(good good bad good bad)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of intermediate split_times to "bad" if time_from_start is impossibly too short' do
        n = 5
        split_times = split_times_104.first(n)
        split_times[1].time_from_start = split_times[0].time_from_start + 1000
        split_times[3].time_from_start = split_times[2].time_from_start + 1000
        split_times_status = %w(good bad good bad good)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of intermediate split_times to "bad" if time_from_start is impossibly too long' do
        n = 4
        split_times = split_times_104.first(n)
        split_times[3].time_from_start = split_times[2].time_from_start + 24.hours
        split_times_status = %w(good good good bad)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of intermediate split_times to "questionable" if time_from_start is probably too short' do
        n = 4
        split_times = split_times_104.first(n)
        split_times[3].time_from_start = split_times[2].time_from_start + 40.minutes
        split_times_status = %w(good good good questionable)
        effort_status = 'questionable'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of intermediate split_times to "questionable" if time_from_start is probably too long' do
        n = 4
        split_times = split_times_104.first(n)
        split_times[3].time_from_start = split_times[2].time_from_start + 5.hours
        split_times_status = %w(good good good questionable)
        effort_status = 'questionable'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'looks past bad or questionable times to determine validity of later split_times' do
        n = 10
        split_times = split_times_104.first(n)
        split_times[7].time_from_start = split_times[6].time_from_start + 1.minute
        split_times[8].time_from_start = split_times[7].time_from_start + 1.minute

        # Much too long from [8] to [9] but reasonable from [6] to [9]
        split_times[9].time_from_start = split_times[8].time_from_start + 5.hours
        split_times_status = %w(good good good good good good good bad bad good)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'works properly for an effort on the fast end of the spectrum of available efforts with all good times' do
        n = 10
        split_times = split_times_109.first(n)
        split_times_status = ['good'] * n
        effort_status = 'good'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'works properly for an effort on the slow end of the spectrum of available efforts with all good times' do
        n = 10
        split_times = split_times_100.first(n)
        split_times_status = ['good'] * n
        effort_status = 'good'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'works properly for an effort on the fast end of the spectrum of available efforts with some bad times' do
        n = 10
        split_times = split_times_109.first(n)
        split_times[7].time_from_start = split_times[6].time_from_start + 1.minute
        split_times[8].time_from_start = split_times[7].time_from_start + 1.minute

        # Much too long from [8] to [9] but reasonable from [6] to [9]
        split_times[9].time_from_start = split_times[8].time_from_start + 4.hours
        split_times_status = %w(good good good good good good good bad bad good)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'works properly for an effort on the slow end of the spectrum of available efforts with some bad times' do
        n = 10
        split_times = split_times_100.first(n)
        split_times[7].time_from_start = split_times[6].time_from_start + 1.minute
        split_times[8].time_from_start = split_times[7].time_from_start + 1.minute

        # Much too long from [8] to [9] but reasonable from [6] to [9]
        split_times[9].time_from_start = split_times[8].time_from_start + 6.hours
        split_times_status = %w(good good good good good good good bad bad good)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'works properly for a full effort with multiple problems' do
        n = 10
        split_times = split_times_105.first(n)
        split_times[0].time_from_start = -60 # Non-zero start time
        split_times[2].time_from_start = split_times[1].time_from_start - 1.minute # Negative time in aid
        split_times[4].time_from_start = split_times[3].time_from_start + 26.hours # Too long in aid
        split_times[7].time_from_start = split_times[6].time_from_start + 20.minutes # Too short for segment
        split_times[9].time_from_start = split_times[8].time_from_start + 10.hours # Too long for segment

        split_times_status = %w(bad good bad good bad good good bad good bad)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'if a split_time has stopped_here = true, sets data_status of all split_times beyond that point to "bad"' do
        n = 10
        split_times = split_times_104.first(n)
        split_times[4].stopped_here = true
        split_times_status = %w(good good good good good bad bad bad bad bad)
        effort_status = 'bad'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      it 'if split_times are all confirmed, sets effort data_status to "good"' do
        n = 3
        split_times = split_times_104.first(n)
        split_times.each { |st| st.data_status = 'confirmed' }
        split_times_status = %w(confirmed confirmed confirmed)
        effort_status = 'good'
        validate_data_status(split_times, split_times_status, effort_status)
      end

      def validate_data_status(split_times, split_times_status, effort_status)
        event = test_event
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(test_splits)
        lap_splits = event.required_lap_splits
        effort = test_effort
        setter = EffortDataStatusSetter.new(effort: effort,
                                            lap_splits: lap_splits,
                                            ordered_split_times: split_times,
                                            times_container: times_container)
        setter.set_data_status
        expect(split_times.map(&:data_status)).to eq(split_times_status)
        expect(effort.data_status).to eq(effort_status)
      end
    end

    context 'for an effort partially underway or completed in a multi-lap event' do
      let(:multi_event) { FactoryGirl.build_stubbed(:event_functional, splits_count: 3, laps_required: 3, efforts_count: 1) }
      let(:multi_effort) { multi_event.efforts.first }
      let(:multi_course) { multi_event.course }
      let(:multi_splits) { multi_course.splits }
      let(:multi_split_times) { multi_effort.split_times }

      it 'sets data_status of all split_times and effort to "good" when split_times fall within expected ranges' do
        n = 10
        split_times = multi_split_times.first(n)
        split_times_status = ['good'] * n
        effort_status = 'good'
        validate_multi_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of beginning split_time to "bad" when starting split_time is not zero' do
        n = 5
        split_times = multi_split_times.first(n)
        split_times[0].time_from_start = 100
        split_times_status = %w(bad good good good good)
        effort_status = 'bad'
        validate_multi_data_status(split_times, split_times_status, effort_status)
      end

      it 'sets data_status of intermediate split_times to "bad" if time_from_start is less than earlier time_from_start' do
        n = 6
        split_times = multi_split_times.first(n)
        split_times[2].time_from_start = split_times[1].time_from_start - 60
        split_times[4].time_from_start = split_times[3].time_from_start - 60
        split_times_status = %w(good good bad good bad good)
        effort_status = 'bad'
        validate_multi_data_status(split_times, split_times_status, effort_status)
      end

      it 'looks past bad or questionable times to determine validity of later split_times' do
        n = 10
        split_times = multi_split_times.first(n)
        split_times[7].time_from_start = split_times[6].time_from_start + 1.minute
        split_times[8].time_from_start = split_times[7].time_from_start + 1.minute

        # Much too long from [8] to [9] but reasonable from [6] to [9]
        split_times[9].time_from_start = split_times[8].time_from_start + 5.hours
        split_times_status = %w(good good good good good good good bad bad good)
        effort_status = 'bad'
        validate_multi_data_status(split_times, split_times_status, effort_status)
      end

      it 'works properly for a full effort with multiple problems' do
        n = 10
        split_times = multi_split_times.first(n)
        split_times[0].time_from_start = -60 # Non-zero start time
        split_times[2].time_from_start = split_times[1].time_from_start - 1.minute # Negative time in aid
        split_times[4].time_from_start = split_times[3].time_from_start + 26.hours # Too long between laps
        split_times[7].time_from_start = split_times[6].time_from_start + 20.minutes # Too short for segment
        split_times[9].time_from_start = split_times[8].time_from_start + 10.hours # Too long for segment

        split_times_status = %w(bad good bad good bad good good bad good bad)
        effort_status = 'bad'
        validate_multi_data_status(split_times, split_times_status, effort_status)
      end

      def validate_multi_data_status(split_times, split_times_status, effort_status)
        event = multi_event
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(multi_splits)
        course = multi_course
        course_distance = multi_splits.last.distance_from_start
        course_vert_gain = multi_splits.last.vert_gain_from_start
        allow(course).to receive(:distance).and_return(course_distance)
        allow(course).to receive(:vert_gain).and_return(course_vert_gain)
        lap_splits = lap_splits_and_time_points(event).first
        lap_splits.each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
        effort = multi_effort
        allow(effort).to receive(:event).and_return(event)
        setter = EffortDataStatusSetter.new(effort: effort,
                                            lap_splits: lap_splits,
                                            ordered_split_times: split_times,
                                            times_container: times_container)
        setter.set_data_status
        expect(split_times.map(&:data_status)).to eq(split_times_status)
        expect(effort.data_status).to eq(effort_status)
      end
    end
  end

  describe '#changed_split_times and #changed_efforts' do
    it 'returns an array containing split_times whose data_status was changed' do
      n = 5
      split_times = split_times_104.first(n)
      expect(split_times[0]).to receive(:changed?).and_return(false)
      expect(split_times[1]).to receive(:changed?).and_return(false)
      expect(split_times[2]).to receive(:changed?).and_return(false)
      course = FactoryGirl.build_stubbed(:course)
      course_distance = test_splits.last.distance_from_start
      allow(course).to receive(:distance).and_return(course_distance)
      event = FactoryGirl.build_stubbed(:event, id: 50, laps_required: 1)
      allow_any_instance_of(Event).to receive(:ordered_splits).and_return(test_splits)
      lap_splits = event.required_lap_splits
      lap_splits.each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      effort = test_effort
      allow(effort).to receive(:event).and_return(event)
      setter = EffortDataStatusSetter.new(effort: effort,
                                          lap_splits: lap_splits,
                                          ordered_split_times: split_times,
                                          times_container: times_container)
      setter.set_data_status
      expect(setter.changed_split_times).to eq(split_times[3..4])
      expect(setter.changed_efforts).to eq([effort])
    end
  end
end