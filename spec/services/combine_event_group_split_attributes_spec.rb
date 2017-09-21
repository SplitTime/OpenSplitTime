require 'rails_helper'

describe CombineEventGroupSplitAttributes do
  describe '.perform' do
    subject { CombineEventGroupSplitAttributes.perform(event_group) }
    let(:event_1) { build_stubbed(:event, splits: event_1_splits) }
    let(:event_2) { build_stubbed(:event, splits: event_2_splits) }
    let(:event_3) { build_stubbed(:event, splits: event_3_splits) }

    let(:event_1_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_1_split_2) { build_stubbed(:split, base_name: 'Aid 1') }
    let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish') }

    let(:event_2_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish') }

    let(:event_3_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_3_split_2) { build_stubbed(:split, base_name: 'Aid 2', sub_split_bitmap: 1) }
    let(:event_3_split_3) { build_stubbed(:finish_split, base_name: 'Finish') }

    let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }
    let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }
    let(:event_3_splits) { [event_3_split_1, event_3_split_2, event_3_split_3] }

    before do
      allow(event_1).to receive(:ordered_splits).and_return(event_1_splits)
      allow(event_2).to receive(:ordered_splits).and_return(event_2_splits)
      allow(event_3).to receive(:ordered_splits).and_return(event_3_splits)
    end


    context 'when the events in the group have splits that are compatible' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }

      it 'returns an array with matching split names grouped together' do
        expected = [{
                        'title' => 'Start',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_1.id, event_2.id => event_2_split_1.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Start'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 1',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 1 In'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 1 Out'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 2',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id, event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 2 In'
                            },
                            {
                                'event_split_ids' => {event_1.id => event_1_split_3.id, event_2.id => event_2_split_2.id},
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 2 Out'
                            }
                        ]
                    },
                    {
                        'title' => 'Finish',
                        'entries' => [
                            {
                                'event_split_ids' => {event_1.id => event_1_split_4.id, event_2.id => event_2_split_3.id},
                                'sub_split_kind' => 'in',
                                'label' => 'Finish'
                            }
                        ]
                    }]

        expect(subject).to eq(expected)
      end
    end

    context 'when splits with matching names do not have matching sub_splits' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2, event_3]) }

      it 'raises an error' do
        expect { subject }.to raise_error(/Splits with matching names must have matching sub_splits/)
      end
    end
  end
end
