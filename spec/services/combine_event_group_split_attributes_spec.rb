# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CombineEventGroupSplitAttributes do
  describe '.perform' do
    subject { CombineEventGroupSplitAttributes.perform(event_group, pair_by_location: pair_by_location, node_attributes: node_attributes) }
    let(:pair_by_location) { false }
    let(:node_attributes) { [:sub_split_kind, :label, :parameterized_split_name, :split_name] }

    let(:event_1) { build_stubbed(:event, splits: event_1_splits) }
    let(:event_2) { build_stubbed(:event, splits: event_2_splits) }

    let(:event_1_split_1) { build_stubbed(:split, :start, base_name: 'Start', latitude: 40, longitude: -105) }
    let(:event_1_split_2) { build_stubbed(:split, base_name: 'Aid 1') }
    let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_1_split_4) { build_stubbed(:split, :finish, base_name: 'Finish', latitude: 40, longitude: -105) }

    let(:event_2_split_1) { build_stubbed(:split, :start, base_name: 'Start', latitude: 40, longitude: -105) }
    let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_2_split_3) { build_stubbed(:split, :finish, base_name: 'Finish', latitude: 40, longitude: -105) }

    let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }
    let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }

    before do
      event_1_splits.each(&:valid?)
      event_2_splits.each(&:valid?)
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
                                'sub_split_kind' => 'in',
                                'label' => 'Start',
                                'parameterized_split_name' => 'start',
                                'split_name' => 'Start'
                            },
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Finish',
                                'parameterized_split_name' => 'finish',
                                'split_name' => 'Finish'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 1',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 1 In',
                                'parameterized_split_name' => 'aid-1',
                                'split_name' => 'Aid 1'
                            },
                            {
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 1 Out',
                                'parameterized_split_name' => 'aid-1',
                                'split_name' => 'Aid 1'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 2',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 2 In',
                                'parameterized_split_name' => 'aid-2',
                                'split_name' => 'Aid 2'
                            },
                            {
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 2 Out',
                                'parameterized_split_name' => 'aid-2',
                                'split_name' => 'Aid 2'
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
                                'sub_split_kind' => 'in',
                                'label' => 'Start',
                                'parameterized_split_name' => 'start',
                                'split_name' => 'Start'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 1',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 1 In',
                                'parameterized_split_name' => 'aid-1',
                                'split_name' => 'Aid 1'
                            },
                            {
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 1 Out',
                                'parameterized_split_name' => 'aid-1',
                                'split_name' => 'Aid 1'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 2',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 2 In',
                                'parameterized_split_name' => 'aid-2',
                                'split_name' => 'Aid 2'
                            },
                            {
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 2 Out',
                                'parameterized_split_name' => 'aid-2',
                                'split_name' => 'Aid 2'
                            }
                        ]
                    },
                    {
                        'title' => 'Finish',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Finish',
                                'parameterized_split_name' => 'finish',
                                'split_name' => 'Finish'
                            }
                        ]
                    }]

        expect(subject).to eq(expected)
      end
    end

    context 'when the events in the group have start in a different location from finish' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:event_1_split_4) { build_stubbed(:split, :finish, base_name: 'Finish', latitude: 41, longitude: -106) }
      let(:event_2_split_3) { build_stubbed(:split, :finish, base_name: 'Finish', latitude: 41, longitude: -106) }

      it 'returns an array with matching split names grouped together' do
        expected = [{
                        'title' => 'Start',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Start',
                                'parameterized_split_name' => 'start',
                                'split_name' => 'Start'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 1',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 1 In',
                                'parameterized_split_name' => 'aid-1',
                                'split_name' => 'Aid 1'
                            },
                            {
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 1 Out',
                                'parameterized_split_name' => 'aid-1',
                                'split_name' => 'Aid 1'
                            }
                        ]
                    },
                    {
                        'title' => 'Aid 2',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Aid 2 In',
                                'parameterized_split_name' => 'aid-2',
                                'split_name' => 'Aid 2'
                            },
                            {
                                'sub_split_kind' => 'out',
                                'label' => 'Aid 2 Out',
                                'parameterized_split_name' => 'aid-2',
                                'split_name' => 'Aid 2'
                            }
                        ]
                    },
                    {
                        'title' => 'Finish',
                        'entries' => [
                            {
                                'sub_split_kind' => 'in',
                                'label' => 'Finish',
                                'parameterized_split_name' => 'finish',
                                'split_name' => 'Finish'
                            }
                        ]
                    }]

        expect(subject).to eq(expected)
      end
    end
  end
end
