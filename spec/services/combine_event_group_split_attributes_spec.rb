require 'rails_helper'

RSpec.describe CombineEventGroupSplitAttributes do
  describe '.perform' do
    subject { CombineEventGroupSplitAttributes.perform(event_group, pair_by_location: pair_by_location) }
    let(:pair_by_location) { false }

    let(:event_1) { build_stubbed(:event, splits: event_1_splits) }
    let(:event_2) { build_stubbed(:event, splits: event_2_splits) }

    let(:event_1_split_1) { build_stubbed(:start_split, base_name: 'Start', latitude: 40, longitude: -105) }
    let(:event_1_split_2) { build_stubbed(:split, base_name: 'Aid 1') }
    let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 40, longitude: -105) }

    let(:event_2_split_1) { build_stubbed(:start_split, base_name: 'Start', latitude: 40, longitude: -105) }
    let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 40, longitude: -105) }

    let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }
    let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }

    before do
      allow(event_1).to receive(:ordered_splits).and_return(event_1_splits)
      allow(event_2).to receive(:ordered_splits).and_return(event_2_splits)
    end


    context 'when the events in the group have start in the same location as finish and pair_by_location is true' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:pair_by_location) { true }

      it 'returns an array with matching split names grouped together' do
        expected = [{
                        'title' => 'Start/Finish',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_1.id, 
                                                      event_2.id => event_2_split_1.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Start',
                                'split_name' => 'start',
                                'display_split_name' => 'Start'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_4.id, 
                                                      event_2.id => event_2_split_3.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Finish',
                                'split_name' => 'finish',
                                'display_split_name' => 'Finish'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 1',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 1 In',
                                'split_name' => 'aid-1',
                                'display_split_name' => 'Aid 1'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 1 Out',
                                'split_name' => 'aid-1',
                                'display_split_name' => 'Aid 1'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 2',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id, 
                                                      event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 2 In',
                                'split_name' => 'aid-2',
                                'display_split_name' => 'Aid 2'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id, 
                                                      event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 2 Out',
                                'split_name' => 'aid-2',
                                'display_split_name' => 'Aid 2'
                            }
                        ]
                    }]

        expect(subject).to eq(expected)
      end
    end

    context 'when the events in the group have start in the same location as finish and pair_by_location is false' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:pair_by_location) { false }

      it 'returns an array with matching split names grouped together' do
        expected = [{
                        'title' => 'Start',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_1.id,
                                                      event_2.id => event_2_split_1.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Start',
                                'split_name' => 'start',
                                'display_split_name' => 'Start'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 1',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 1 In',
                                'split_name' => 'aid-1',
                                'display_split_name' => 'Aid 1'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 1 Out',
                                'split_name' => 'aid-1',
                                'display_split_name' => 'Aid 1'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 2',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id,
                                                      event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 2 In',
                                'split_name' => 'aid-2',
                                'display_split_name' => 'Aid 2'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id,
                                                      event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 2 Out',
                                'split_name' => 'aid-2',
                                'display_split_name' => 'Aid 2'
                            }
                        ]
                    },
                    {
                        'title' => 'Finish',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_4.id,
                                                      event_2.id => event_2_split_3.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Finish',
                                'split_name' => 'finish',
                                'display_split_name' => 'Finish'
                            }
                        ]
                    }]

        expect(subject).to eq(expected)
      end
    end

    context 'when the events in the group have start in a different location from finish' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 41, longitude: -106) }
      let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 41, longitude: -106) }

      it 'returns an array with matching split names grouped together' do
        expected = [{
                        'title' => 'Start',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_1.id, 
                                                      event_2.id => event_2_split_1.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Start',
                                'split_name' => 'start',
                                'display_split_name' => 'Start'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 1',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 1 In',
                                'split_name' => 'aid-1',
                                'display_split_name' => 'Aid 1'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 1 Out',
                                'split_name' => 'aid-1',
                                'display_split_name' => 'Aid 1'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 2',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id, 
                                                      event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 2 In',
                                'split_name' => 'aid-2',
                                'display_split_name' => 'Aid 2'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id, 
                                                      event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 2 Out',
                                'split_name' => 'aid-2',
                                'display_split_name' => 'Aid 2'
                            }
                        ]
                    },
                    {
                        'title' => 'Finish',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_4.id, 
                                                      event_2.id => event_2_split_3.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Finish',
                                'split_name' => 'finish',
                                'display_split_name' => 'Finish'
                            }
                        ]
                    }]

        expect(subject).to eq(expected)
      end
    end
  end
end
