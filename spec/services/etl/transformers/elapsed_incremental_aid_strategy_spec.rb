require 'rails_helper'

RSpec.describe ETL::Transformers::ElapsedIncrementalAidStrategy do
  subject { ETL::Transformers::ElapsedIncrementalAidStrategy.new(struct, options) }

  let(:struct) { OpenStruct.new(attributes) }
  let(:attributes) { {full_name: 'William Abel', gender: 'male', age: '41', city: 'Byron', state_code: 'IL', times: times} }
  let(:options) { {event: event} }

  let(:proto_records) { subject.transform }
  let(:first_proto_record) { proto_records.first }

  let(:event) { build_stubbed(:event, course: course) }
  let(:course) { build_stubbed(:course) }
  let(:start) { build_stubbed(:start_split, course: course, base_name: 'Start') }
  let(:dry_fork) { build_stubbed(:split, course: course, base_name: 'Dry Fork Outbound', sub_split_bitmap: 65, distance_from_start: 17220) }
  let(:foot_bridge) { build_stubbed(:split, course: course, base_name: 'Foot Bridge Outbound', sub_split_bitmap: 65, distance_from_start: 31704) }
  let(:jaws) { build_stubbed(:split, course: course, base_name: 'Jaws', sub_split_bitmap: 65, distance_from_start: 36210) }
  let(:finish) { build_stubbed(:split, course: course, base_name: 'Finish', sub_split_bitmap: 1, distance_from_start: 50000) }
  let(:splits) { [start, dry_fork, foot_bridge, jaws, finish] }
  before do
    allow(course).to receive(:splits).and_return(splits)
    allow(event).to receive(:splits).and_return(splits)
  end

  describe '#transform' do
    context 'when time data is in expected order and contains no holes' do
      let(:times) { {'DF In' => '3:27:40.00', 'DF Out' => '05:24.00', 'FB In' => '7:18:29.00', 'FB Out' => '05:01.00',
                     'Jaws In' => '13:02:36.00', 'Jaws Out' => '16:18.00', 'Finish' => '27:44:15.52'} }
      let(:time_points) { event.required_time_points }

      it 'returns a single ProtoRecord parent' do
        expect(proto_records.size).to eq(1)
        expect(first_proto_record).to be_a(ProtoRecord)
      end

      it 'transforms effort headers to match the database' do
        expect(first_proto_record.to_h.keys.sort)
            .to match_array(%i(age event_id first_name gender last_name city state_code country_code))
      end

      it 'returns genders transformed to "male" or "female"' do
        expect(first_proto_record[:gender]).to eq('male')
      end

      it 'splits full names into first names and last names' do
        expect(first_proto_record[:first_name]).to eq('William')
        expect(first_proto_record[:last_name]).to eq('Abel')
      end

      it 'assigns event.id to :event_id key' do
        expect(first_proto_record[:event_id]).to eq(event.id)
      end

      it 'returns an array of children with times in expected order' do
        records = first_proto_record.children
        expect(records.size).to eq(8)
        expect(records.map(&:record_type)).to all eq(:split_time)
        expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
        expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
        expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
        expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, 12460.0, 12784.0, 26309.0, 26610.0, 46956.0, 47934.0, 99855.52])
      end

      it 'sets [:stopped_here] attribute on the final child record' do
        records = first_proto_record.children
        expect(records.reverse.find { |pr| pr[:time_from_start].present? }[:stopped_here]).to eq(true)
        expect(records.map { |pr| pr[:stopped_here] }).to eq([nil] * 7 + [true])
      end
    end

    context 'when time data contains holes' do
      let(:times) { {'DF In' => '3:27:40.00', 'DF Out' => '05:24.00', 'FB In' => '7:18:29.00', 'FB Out' => '--',
                     'Jaws In' => '--', 'Jaws Out' => '--', 'Finish' => '27:44:15.52'} }
      let(:time_points) { event.required_time_points[0..3] + event.required_time_points[-1..-1] }

      it 'returns an array of children with times in expected order, skipping time_points that have no associated times' do
        records = first_proto_record.children
        expect(records.size).to eq(5)
        expect(records.map(&:record_type)).to eq([:split_time] * records.size)
        expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
        expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
        expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
        expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, 12460.0, 12784.0, 26309.0, 99855.52])
      end

      it 'sets [:stopped_here] attribute on the final child record' do
        records = first_proto_record.children
        expect(records.reverse.find { |pr| pr[:time_from_start].present? }[:stopped_here]).to eq(true)
        expect(records.map { |pr| pr[:stopped_here] }).to eq([nil] * 4 + [true])
      end
    end

    context 'when time data has no time information' do
      let(:times) { {'DF In' => '--', 'DF Out' => '--', 'FB In' => '--', 'FB Out' => '--',
                     'Jaws In' => '--', 'Jaws Out' => '--', 'Finish' => '--'} }
      let(:time_points) { event.required_time_points[0..3] + event.required_time_points[-1..-1] }

      it 'returns an empty array of children' do
        records = first_proto_record.children
        expect(records).to be_empty
      end
    end
  end
end
