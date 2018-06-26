require 'rails_helper'

RSpec.describe RawTimePairer do
  subject { RawTimePairer.new(event_group: event_group, raw_times: raw_times) }
  let(:event_group) { build_stubbed(:event_group) }
  let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'cunningham', bitkey: 1, stopped_here: false) }
  let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'cunningham', bitkey: 64, stopped_here: true) }
  let(:raw_time_3) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '11', split_name: 'cunningham', bitkey: 1, with_pacer: true) }
  let(:raw_time_4) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '11', split_name: 'cunningham', bitkey: 64, with_pacer: true) }
  let(:raw_time_5) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'maggie', bitkey: 1) }
  let(:raw_time_6) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'maggie', bitkey: 64) }
  let(:raw_time_7) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'cunningham', bitkey: 64) }
  let(:raw_time_bad_split) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'bad-split', bitkey: 1) }
  let(:raw_time_wildcard_1) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10*', split_name: 'cunningham', bitkey: 1) }
  let(:raw_time_wildcard_2) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10*', split_name: 'cunningham', bitkey: 64) }


  describe '#pair' do
    context 'when all raw_times can be paired' do
      let(:raw_times) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_5, raw_time_6, raw_time_7] }

      it 'returns an array of paired raw_time arrays' do
        expected = [[raw_time_1, raw_time_2], [nil, raw_time_7], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6]]
        expect(subject.pair).to eq(expected)
      end

      it 'retains boolean attributes' do
        expect(subject.pair.first.map(&:stopped_here)).to eq([false, true])
        expect(subject.pair.third.map(&:with_pacer)).to eq([true, true])
      end
    end

    context 'when raw_times contain wildcard characters' do
      let(:raw_times) { [raw_time_1, raw_time_2, raw_time_wildcard_1, raw_time_wildcard_2] }

      it 'pairs matching wildcard bib_numbers with each other but not with any other raw_time' do
        expected = [[raw_time_1, raw_time_2], [raw_time_wildcard_1, raw_time_wildcard_2]]
        expect(subject.pair).to eq(expected)
      end
    end
  end
end
