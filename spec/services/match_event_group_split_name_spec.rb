require 'rails_helper'

RSpec.describe MatchEventGroupSplitName do
  describe '.perform' do
    subject { MatchEventGroupSplitName.perform(event_group, base_name) }
    let(:event_1) { build_stubbed(:event, splits: event_1_splits) }
    let(:event_2) { build_stubbed(:event, splits: event_2_splits) }
    let(:event_3) { build_stubbed(:event, splits: event_3_splits) }

    let(:event_1_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_1_split_2) { build_stubbed(:split, base_name: 'Aid 1') }
    let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish') }
    
    let(:event_1_aid_1) { build_stubbed(:aid_station, event: event_1, split: event_1_split_1) }
    let(:event_1_aid_2) { build_stubbed(:aid_station, event: event_1, split: event_1_split_2) }
    let(:event_1_aid_3) { build_stubbed(:aid_station, event: event_1, split: event_1_split_3) }
    let(:event_1_aid_4) { build_stubbed(:aid_station, event: event_1, split: event_1_split_4) }

    let(:event_2_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish') }

    let(:event_2_aid_1) { build_stubbed(:aid_station, event: event_2, split: event_2_split_1) }
    let(:event_2_aid_2) { build_stubbed(:aid_station, event: event_2, split: event_2_split_2) }
    let(:event_2_aid_3) { build_stubbed(:aid_station, event: event_2, split: event_2_split_3) }

    let(:event_3_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_3_split_2) { build_stubbed(:split, base_name: 'Aid 2', sub_split_bitmap: 1) }
    let(:event_3_split_3) { build_stubbed(:finish_split, base_name: 'Finish') }

    let(:event_3_aid_1) { build_stubbed(:aid_station, event: event_3, split: event_3_split_1) }
    let(:event_3_aid_2) { build_stubbed(:aid_station, event: event_3, split: event_3_split_2) }
    let(:event_3_aid_3) { build_stubbed(:aid_station, event: event_3, split: event_3_split_3) }

    let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }
    let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }
    let(:event_3_splits) { [event_3_split_1, event_3_split_2, event_3_split_3] }

    let(:event_1_aid_stations) { [event_1_aid_1, event_1_aid_2, event_1_aid_3, event_1_aid_4] }
    let(:event_2_aid_stations) { [event_2_aid_1, event_2_aid_2, event_2_aid_3] }
    let(:event_3_aid_stations) { [event_3_aid_1, event_3_aid_2, event_3_aid_3] }

    before do
      allow(event_1).to receive(:ordered_splits).and_return(event_1_splits)
      allow(event_2).to receive(:ordered_splits).and_return(event_2_splits)
      allow(event_3).to receive(:ordered_splits).and_return(event_3_splits)

      allow(event_1).to receive(:aid_stations).and_return(event_1_aid_stations)
      allow(event_2).to receive(:aid_stations).and_return(event_2_aid_stations)
      allow(event_3).to receive(:aid_stations).and_return(event_3_aid_stations)
    end


    context 'when splits with matching names have matching sub_splits' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:base_name) { 'Aid 2' }

      it 'returns a hash with matching splits and aid_stations grouped together' do
        expected = {event_splits: {event_1.id => event_1_split_3, event_2.id => event_2_split_2},
                    event_aid_stations: {event_1.id => event_1_aid_3, event_2.id => event_2_aid_2}}
        
        expect(subject).to eq(expected)
      end
    end

    context 'when splits with matching names do not have matching sub_splits' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2, event_3]) }
      let(:base_name) { 'Aid 2' }

      it 'raises an error' do
        expect { subject }.to raise_error(/Splits with matching names must have matching sub_splits/)
      end
    end
  end
end
