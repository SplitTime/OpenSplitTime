# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ETL::Transformers::AdilasBearStrategy do
  subject { ETL::Transformers::AdilasBearStrategy.new(struct, options) }

  let(:struct) { OpenStruct.new(attributes) }
  let(:attributes) { {full_name: 'Linda McFadden', bib_number: '187', gender: 'F', age: '54', city: 'Modesto', state_code: 'CA', times: times, dnf: dnf} }
  let(:dnf) { true }
  let(:options) { {parent: event} }

  let(:proto_records) { subject.transform }
  let(:first_proto_record) { proto_records.first }

  let(:event) { build_stubbed(:event, course: course, start_time_local: '9/23/2016 6:00:00', event_group: event_group) }
  let(:event_group) { build(:event_group, home_time_zone: 'Mountain Time (US & Canada)')}
  let(:start_time) { event.start_time }
  let(:course) { build_stubbed(:course) }
  let(:start) { build_stubbed(:split, :start, course: course, base_name: 'Start') }
  let(:logan) { build_stubbed(:split, course: course, base_name: 'Logan', sub_split_bitmap: 65, distance_from_start: 17220) }
  let(:leatham) { build_stubbed(:split, course: course, base_name: 'Leatham', sub_split_bitmap: 65, distance_from_start: 31704) }
  let(:richards) { build_stubbed(:split, course: course, base_name: 'Richards', sub_split_bitmap: 65, distance_from_start: 36210) }
  let(:cowley) { build_stubbed(:split, course: course, base_name: 'Cowley', sub_split_bitmap: 65, distance_from_start: 48280) }
  let(:splits) { [start, logan, leatham, richards, cowley] }
  before do
    allow(course).to receive(:splits).and_return(splits)
    allow(event).to receive(:splits).and_return(splits)
  end

  describe '#transform' do
    context 'when time data is in expected order and contains no holes' do
      let(:times) { {0 => ['9/23/2016 6:00:00 am', '9/23/2016 8:49:10 am'],
                     1 => ['9/23/2016 8:49:10 am', '9/23/2016 12:30:27 pm'],
                     2 => ['9/23/2016 12:30:29 pm', '9/24/2016 1:49:11 pm'],
                     3 => ['9/23/2016 1:49:11 pm', '... ...']} }
      let(:time_points) { event.required_time_points.first(7) }

      it 'returns a single ProtoRecord parent' do
        expect(proto_records.size).to eq(1)
        expect(first_proto_record).to be_a(ProtoRecord)
      end

      it 'transforms effort headers to match the database' do
        expect(first_proto_record.to_h.keys.sort)
            .to match_array(%i(age bib_number event_id first_name gender last_name city state_code country_code))
      end

      it 'returns genders transformed to "male" or "female"' do
        expect(first_proto_record[:gender]).to eq('female')
      end

      it 'splits full names into first names and last names' do
        expect(first_proto_record[:first_name]).to eq('Linda')
        expect(first_proto_record[:last_name]).to eq('McFadden')
      end

      it 'assigns event.id to :event_id key' do
        expect(first_proto_record[:event_id]).to eq(event.id)
      end

      it 'returns an array of children with times in expected order' do
        records = first_proto_record.children
        expect(records.size).to eq(7)
        expect(records.map(&:record_type)).to eq([:split_time] * records.size)
        expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
        expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
        expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
        expect(records.map { |pr| pr[:absolute_time] }).to eq([0, 10150, 10150, 23427, 23429, 114551, 28151].map { |e| start_time + e })
      end

      context 'when dnf is true' do
        let(:dnf) { true }

        it 'sets [:stopped_here] attribute on the final child record' do
          records = first_proto_record.children
          expect(records.reverse.find { |pr| pr[:absolute_time].present? }[:stopped_here]).to eq(true)
          expect(records.map { |pr| pr[:stopped_here] }).to eq([nil, nil, nil, nil, nil, nil, true])
        end
      end

      context 'when dnf is false' do
        let(:dnf) { false }

        it 'does not set [:stopped_here] attribute on the final child record' do
          records = first_proto_record.children
          expect(records.reverse.find { |pr| pr[:absolute_time].present? }[:stopped_here]).to eq(nil)
          expect(records.map { |pr| pr[:stopped_here] }).to eq([nil, nil, nil, nil, nil, nil, nil])
        end
      end
    end

    context 'when time data is not in expected order and contains holes' do
      let(:times) { {0 => ['9/23/2016 6:00:00 am', '9/23/2016 8:49:10 am'],
                     2 => ['9/23/2016 12:30:29 pm', '9/23/2016 1:49:11 pm'],
                     1 => ['9/23/2016 8:49:10 am', '9/23/2016 12:30:27 pm'],
                     4 => ['9/23/2016 3:49:11 pm', '... ...']} }
      let(:time_points) { event.required_time_points[0..5] + event.required_time_points[8..8] }

      it 'returns an array of children with times in expected order, skipping time_points that have no associated times' do
        records = first_proto_record.children
        expect(records.size).to eq(7)
        expect(records.map(&:record_type)).to eq([:split_time] * records.size)
        expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
        expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
        expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
        expect(records.map { |pr| pr[:absolute_time] }).to eq([0, 10150, 10150, 23427, 23429, 28151, 35351].map { |e| start_time + e })
      end

      it 'sets [:stopped_here] attribute on the final child record' do
        records = first_proto_record.children
        expect(records.reverse.find { |pr| pr[:absolute_time].present? }[:stopped_here]).to eq(true)
        expect(records.map { |pr| pr[:stopped_here] }).to eq([nil] * 6 + [true])
      end
    end

    context 'when time data is behind by up to 7 days, resulting in negative times from start' do
      let(:times) { {0 => ['9/23/2016 6:00:00 am', '9/23/2016 8:49:10 am'],
                     1 => ['9/23/2016 8:49:10 am', '9/23/2016 12:30:27 pm'],
                     2 => ['9/16/2016 12:30:29 pm', '9/18/2016 1:49:11 pm'],
                     3 => ['9/23/2016 3:49:11 pm', '... ...']} }
      let(:time_points) { event.required_time_points.first(7) }

      it 'adds the number of days needed to make absolute_time greater than the starting absolute_time' do
        records = first_proto_record.children
        expect(records.size).to eq(7)
        expect(records.map(&:record_type)).to eq([:split_time] * records.size)
        expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
        expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
        expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
        expect(records.map { |pr| pr[:absolute_time] }).to eq([0, 10150, 10150, 23427, 23429, 28151, 35351].map { |e| start_time + e })
      end
    end
  end
end
