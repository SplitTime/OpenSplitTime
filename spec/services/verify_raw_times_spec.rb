require 'rails_helper'

RSpec.describe VerifyRawTimes do
  subject { VerifyRawTimes.new(raw_times: raw_times, effort: effort, event: event) }

  let!(:event_group) { create(:event_group) }
  let!(:event) { create(:event, event_group: event_group, course: course, laps_required: 1) }
  let(:effort) { Effort.where(event: event).includes(:split_times).first }
  let!(:course) { create(:course) }
  let!(:start_split) { create(:start_split, course: course)}
  let!(:cunningham_split) { create(:split, course: course, base_name: 'Cunningham') }
  let(:splits) { [start_split, cunningham_split] }

  before do
    event.splits << splits
    create(:effort, event: event, bib_number: 10)
    create(:split_time, split: start_split, bitkey: 1, effort: effort, time_from_start: 0)
    create(:split_time, split: cunningham_split, bitkey: 1, effort: effort, time_from_start: 7200)
  end

  let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'cunningham', bitkey: 1, stopped_here: false) }
  let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'cunningham', bitkey: 64, stopped_here: true) }

  describe '#perform' do
    context 'when all bib_numbers match' do
      let(:raw_times) { RawTime.where(bib_number: %w(10)).with_relation_ids.to_a }
      before { raw_times.each { |rt| rt.lap = 1 } }

      it 'returns raw_times with existing_times_count and data_status attributes' do
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:existing_times_count)).to all be_nil
        expect(raw_times.map(&:data_status)).to all be_nil
        subject.perform
        expect(raw_times.size).to eq(2)
      end
    end
  end
end
