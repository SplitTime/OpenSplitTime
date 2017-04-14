require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EventSpreadDisplay do
  let(:test_course) { FactoryGirl.build_stubbed(:course, id: 10, name: 'Testrock Counter-clockwise') }
  let(:test_event) { FactoryGirl.build_stubbed(:event, name: 'Testrock 100', id: 50) }
  let(:split_names_without_start) { ['Cunningham In', 'Cunningham Out', 'Maggie In', 'Maggie Out',
                                     'Pole Creek In', 'Pole Creek Out', 'Sherman In', 'Sherman Out', 'Burrows In', 'Burrows Out',
                                     'Grouse In', 'Grouse Out', 'Engineer In', 'Engineer Out', 'Ouray In', 'Ouray Out',
                                     'Governor In', 'Governor Out', 'Kroger In', 'Kroger Out', 'Telluride In', 'Telluride Out',
                                     'Chapman In', 'Chapman Out', 'Kamm Traverse In', 'Kamm Traverse Out', 'Putnam In', 'Putnam Out', 'Finish'] }
  let(:split_names_with_start) { split_names_without_start.unshift('Start') }

  context 'when display_style is ampm' do
    let(:prepared_params) { ActionController::Parameters.new(display_style: 'ampm') }

    describe '#split_header_names' do
      before do
        FactoryGirl.reload
      end

      let(:split_times_100) { FactoryGirl.build_stubbed_list(:split_times_hardrock_0, 10, effort_id: 100) }
      let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_hardrock_1, 10, effort_id: 101) }
      let(:split_times_102) { FactoryGirl.build_stubbed_list(:split_times_hardrock_2, 10, effort_id: 102) }
      let(:split_times_103) { FactoryGirl.build_stubbed_list(:split_times_hardrock_3, 10, effort_id: 103) }
      let(:split_times_104) { FactoryGirl.build_stubbed_list(:split_times_hardrock_4, 10, effort_id: 104) }
      let(:split_times_105) { FactoryGirl.build_stubbed_list(:split_times_hardrock_5, 10, effort_id: 105) }
      let(:split_times_106) { FactoryGirl.build_stubbed_list(:split_times_hardrock_6, 10, effort_id: 106) }
      let(:split_times_107) { FactoryGirl.build_stubbed_list(:split_times_hardrock_7, 10, effort_id: 107) }
      let(:split_times_108) { FactoryGirl.build_stubbed_list(:split_times_hardrock_8, 10, effort_id: 108) }
      let(:split_times_109) { FactoryGirl.build_stubbed_list(:split_times_hardrock_9, 10, effort_id: 109) }
      let(:splits) { FactoryGirl.build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }
      let(:efforts) { FactoryGirl.build_stubbed_list(:efforts_hardrock, 10, event_id: 50) }

      it 'returns correct split names with extensions for all splits other than the start_split' do
        skip
        event = test_event
        allow(event).to receive(:ordered_splits).and_return(splits)
        allow(event).to receive(:efforts).and_return(efforts)
        spread_display = EventSpreadDisplay.new(event: event, params: prepared_params)
        allow(spread_display).to receive(:efforts).and_return(efforts)
        actual = spread_display.split_header_names
        expected = split_names_without_start
        expect(actual).to eq(expected)
      end
    end
  end
end
