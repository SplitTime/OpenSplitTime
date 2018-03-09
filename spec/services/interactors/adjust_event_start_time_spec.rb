require 'rails_helper'

RSpec.describe Interactors::AdjustEventStartTime do
  let(:response) { Interactors::AdjustEventStartTime.perform!(event, new_start_time: new_start_time) }

  let(:event) { create(:event_with_standard_splits, splits_count: 3, laps_required: 1) }
  let(:efforts) { create_list(:effort, 2, event: event) }
  let!(:original_start_time) { event.start_time }
  let(:new_start_time) { (event.start_time + adjustment).to_s }

  before do
    time_points = event.required_lap_splits.flat_map(&:time_points)
    SplitTime.create!(effort: efforts.first, time_point: time_points.first, time_from_start: 0)
    SplitTime.create!(effort: efforts.first, time_point: time_points.second, time_from_start: 1000)
    SplitTime.create!(effort: efforts.first, time_point: time_points.third, time_from_start: 2000)
    SplitTime.create!(effort: efforts.first, time_point: time_points.fourth, time_from_start: 3000)
    SplitTime.create!(effort: efforts.second, time_point: time_points.first, time_from_start: 0)
    SplitTime.create!(effort: efforts.second, time_point: time_points.second, time_from_start: 1500)
    SplitTime.create!(effort: efforts.second, time_point: time_points.third, time_from_start: 2500)
  end

  context 'when the event start time has moved forward' do
    let(:adjustment) { 100 }

    it 'adjusts all non-start split times backward by the same amount' do
      response
      event.reload

      expect(event.start_time).to eq(original_start_time + 100)
      expect(SplitTime.all.pluck(:time_from_start)).to match_array([0, 900, 1900, 2900, 0, 1400, 2400])
      expect(response.message).to include("Start time for #{event.name} was changed")
      expect(response.message).to include('Split times were adjusted backward by 100.0 seconds')
    end
  end

  context 'when the event start time has moved backward' do
    let(:adjustment) { -100 }

    it 'adjusts all non-start split times forward by the same amount' do
      response
      event.reload

      expect(event.start_time).to eq(original_start_time - 100)
      expect(SplitTime.all.pluck(:time_from_start)).to match_array([0, 1100, 2100, 3100, 0, 1600, 2600])
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
end
