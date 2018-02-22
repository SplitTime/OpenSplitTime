require 'rails_helper'

RSpec.describe EventSpreadDisplay do
  subject { EventSpreadDisplay.new(event: event, params: prepared_params) }
  let(:prepared_params) { ActionController::Parameters.new(display_style: 'ampm') }

  describe '#split_header_data' do
    let(:course) { build_stubbed(:course, name: 'Testrock Counter-clockwise', splits: splits) }
    let(:event) { build_stubbed(:event, name: 'Testrock 100', course: course, splits: splits) }
    let(:splits) { [split_1, split_2, split_3] }
    let(:split_1) { build_stubbed(:start_split, base_name: 'Starting Point') }
    let(:split_2) { build_stubbed(:split, base_name: 'Aid Station 1', distance_from_start: 10000) }
    let(:split_3) { build_stubbed(:finish_split, base_name: 'Finishing Point', distance_from_start: 20000) }

    it 'returns an array of hashes containing title, extensions, and distances' do
      expected = [
        {title: 'Starting Point', extensions: [], distance: 0},
        {title: 'Aid Station 1', extensions: %w(In Out), distance: 10000},
        {title: 'Finishing Point', extensions: [], distance: 20000}
      ]
      expect(subject.split_header_data).to eq(expected)
    end
  end

  describe '#display_style' do
    context 'when display_style is provided in the params' do
      let(:prepared_params) { ActionController::Parameters.new(display_style: 'ampm') }
      let(:event) { instance_double('Event', simple?: true, event_group: event_group) }
      let(:event_group) { instance_double('EventGroup', available_live: true) }

      it 'returns the provided display_style' do
        expect(subject.display_style).to eq('ampm')
      end
    end

    context 'when display_style is not provided in the params and the event has only start/finish splits' do
      let(:prepared_params) { ActionController::Parameters.new(display_style: nil) }
      let(:event) { instance_double('Event', simple?: true, event_group: event_group) }
      let(:event_group) { instance_double('EventGroup', available_live: true) }

      it 'returns elapsed' do
        expect(subject.display_style).to eq('elapsed')
      end
    end

    context 'when display_style is not provided in the params and the event has multiple splits and is available live' do
      let(:prepared_params) { ActionController::Parameters.new(display_style: nil) }
      let(:event) { instance_double('Event', simple?: false, event_group: event_group) }
      let(:event_group) { instance_double('EventGroup', available_live: true) }

      it 'returns elapsed' do
        expect(subject.display_style).to eq('ampm')
      end
    end

    context 'when display_style is not provided in the params and the event has multiple splits and is not available live' do
      let(:prepared_params) { ActionController::Parameters.new(display_style: nil) }
      let(:event) { instance_double('Event', simple?: false, event_group: event_group) }
      let(:event_group) { instance_double('EventGroup', available_live: false) }

      it 'returns elapsed' do
        expect(subject.display_style).to eq('elapsed')
      end
    end
  end
end
