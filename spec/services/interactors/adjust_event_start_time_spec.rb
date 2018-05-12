require 'rails_helper'

RSpec.describe Interactors::AdjustEventStartTime do
  let(:response) { Interactors::AdjustEventStartTime.perform!(event, new_start_time: new_start_time) }

  let(:event) { create(:event_with_standard_splits, splits_count: 3, laps_required: 1) }
  let(:effort_1) { create(:effort, event: event) }
  let(:effort_2) { create(:effort, event: event) }
  let(:effort_with_offset) { create(:effort, event: event, start_offset: -3600) }
  let!(:original_start_time) { event.start_time }
  let(:new_start_time) { (event.start_time + adjustment).to_s }

  before do
    time_points = event.required_lap_splits.flat_map(&:time_points)
    effort_1.split_times.create!(time_point: time_points.first, time_from_start: 0)
    effort_1.split_times.create!(time_point: time_points.second, time_from_start: 1000)
    effort_1.split_times.create!(time_point: time_points.third, time_from_start: 2000)
    effort_1.split_times.create!(time_point: time_points.fourth, time_from_start: 3000)
    effort_2.split_times.create!(time_point: time_points.first, time_from_start: 0)
    effort_2.split_times.create!(time_point: time_points.second, time_from_start: 1500)
    effort_2.split_times.create!(time_point: time_points.third, time_from_start: 2500)
  end

  context 'when the event start time has moved forward' do
    let(:adjustment) { 100 }

    it 'adjusts all non-start split times backward by the same amount to retain absolute times constant' do
      response
      event.reload

      expect(event.start_time).to eq(original_start_time + 100)
      expect(effort_1.ordered_split_times.pluck(:time_from_start)).to eq([0, 900, 1900, 2900])
      expect(effort_2.ordered_split_times.pluck(:time_from_start)).to eq([0, 1400, 2400])
      expect(response.message).to include("Start time for #{event.name} was changed")
      expect(response.message).to include('Split times were adjusted backward by 100.0 seconds')
    end
  end

  context 'when the event start time has moved backward' do
    let(:adjustment) { -100 }

    it 'adjusts all non-start split times forward by the same amount to retain absolute times constant' do
      response
      event.reload

      expect(event.start_time).to eq(original_start_time - 100)
      expect(effort_1.ordered_split_times.pluck(:time_from_start)).to eq([0, 1100, 2100, 3100])
      expect(effort_2.ordered_split_times.pluck(:time_from_start)).to eq([0, 1600, 2600])
      expect(response.message).to include("Start time for #{event.name} was changed")
      expect(response.message).to include('Split times were adjusted forward by 100.0 seconds')
    end
  end

  context 'when the event start time has moved forward beyond the time of any time_from_start' do
    let(:adjustment) { 1200 }

    it 'does not adjust the event start time or any times but returns descriptive errors' do
      response
      event.reload

      expect(event.start_time).to eq(original_start_time)
      expect(SplitTime.all.pluck(:time_from_start)).to match_array([0, 1000, 2000, 3000, 0, 1500, 2500])
      expect(response.error_report).to include('Time from start must be greater than or equal to 0')
      expect(response.message).to include('Unable to update event start time')
    end
  end

  context 'when the event start time has not changed' do
    let(:adjustment) { 0 }

    it 'does not adjust any times' do
      response
      event.reload

      expect(event.start_time).to eq(original_start_time)
      expect(SplitTime.all.pluck(:time_from_start)).to match_array([0, 1000, 2000, 3000, 0, 1500, 2500])
      expect(response.message).to include("Start time for #{event.name} was not changed")
    end
  end

  context 'when any effort is offset from the event start_time' do
    before do

    end
  end
end
