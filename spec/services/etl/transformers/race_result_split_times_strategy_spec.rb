require 'rails_helper'

RSpec.describe ETL::Transformers::RaceResultSplitTimesStrategy do
  subject { ETL::Transformers::RaceResultSplitTimesStrategy.new(parsed_structs, options) }
  let(:options) { {event: event} }
  let(:proto_records) { subject.transform }
  let(:first_proto_record) { proto_records.first }
  let(:second_proto_record) { proto_records.second }
  let(:third_proto_record) { proto_records.third }
  let(:fourth_proto_record) { proto_records.fourth }
  let(:fifth_proto_record) { proto_records.fifth }
  let(:last_proto_record) { proto_records.last }

  describe '#transform' do
    context 'when event is present and splits count matches split fields count' do
      before do
        _, time_points = lap_splits_and_time_points(event)
        allow(event).to receive(:required_time_points).and_return(time_points)
      end

      context 'when the parsed structs contain one or more section splits in addition to the finish time' do
        let(:event) { build_stubbed(:event_with_standard_splits, id: 1, in_sub_splits_only: true, splits_count: 7) }
        let(:parsed_structs) { [
            OpenStruct.new(rr_id: '5', place: '3', bib: '5', name: 'Jatest Schtest', sex: 'M', age: '39',
                           section1_split: '0:43:01.36', section4_split: '1:08:27.81', section5_split: '0:51:23.93',
                           section2_split: '1:02:07.50', section3_split: '0:52:34.70', section6_split: '0:18:01.15',
                           elapsed: '4:55:36.43', time: '4:55:36.43', pace: '09:30'),
            OpenStruct.new(rr_id: '327', place: '67', bib: '327', name: 'Sutest Ritest', sex: 'F', age: '46',
                           section1_split: '0:53:21.92', section2_split: '1:21:42.05', section3_split: '',
                           section4_split: '', section5_split: '1:10:55.96', section6_split: '0:22:11.96',
                           elapsed: '6:32:45.84', time: '6:32:45.84', pace: '12:38'),
            OpenStruct.new(rr_id: '661', place: '*', bib: '661', name: 'Castest Pertest', sex: 'F', age: '31',
                           section1_split: '1:21:56.63', section2_split: '2:38:01.85', section3_split: '',
                           section4_split: '', section5_split: '', section6_split: '',
                           elapsed: '3:59:58.48', time: 'DNF', pace: '*'),
            OpenStruct.new(rr_id: '662', place: '*', bib: '662', name: 'Bestest Sartest', sex: 'M', age: '31',
                           section1_split: '1:21:56.63', section2_split: '2:38:01.85', section3_split: '',
                           section4_split: '', section5_split: '', section6_split: '',
                           elapsed: '3:59:58.48', time: 'DSQ', pace: '*'),
            OpenStruct.new(rr_id: '633', place: '*', bib: '633', name: 'Mictest Hintest', sex: 'F', age: '35',
                           section1_split: '', section2_split: '', section3_split: '',
                           section4_split: '', section5_split: '', section6_split: '',
                           elapsed: '', time: 'DNS', pace: '*'),
            OpenStruct.new(rr_id: '62', place: '*', bib: '62', name: 'N.n. 62', sex: '', age: 'n/a',
                           section1_split: '', section2_split: '', section3_split: '',
                           section4_split: '', section5_split: '', section6_split: '',
                           elapsed: '', time: '', pace: '*')
        ] }

        it 'returns the same number of ProtoRecords as it is given OpenStructs' do
          expect(proto_records.size).to eq(6)
          expect(proto_records.all? { |row| row.is_a?(ProtoRecord) }).to eq(true)
        end

        it 'returns rows with effort headers transformed to match the database' do
          expect(first_proto_record.to_h.keys.sort)
              .to eq(%i(age bib_number event_id first_name gender last_name))
        end

        it 'returns genders transformed to "male" or "female"' do
          expect(proto_records.map { |pr| pr[:gender] }).to eq(['male', 'female', 'female', 'male', 'female', ''])
        end

        it 'splits full names into first names and last names' do
          expect(proto_records.map { |pr| pr[:first_name] }).to eq(%w(Jatest Sutest Castest Bestest Mictest N.n.))
          expect(proto_records.map { |pr| pr[:last_name] }).to eq(%w(Schtest Ritest Pertest Sartest Hintest 62))
        end

        it 'assigns event.id to :event_id key' do
          expect(proto_records.map { |pr| pr[:event_id] }).to eq([event.id] * parsed_structs.size)
        end

        it 'sorts split headers and returns an array of children' do
          records = first_proto_record.children
          time_points = event.required_time_points
          expect(records.size).to eq(7)
          expect(records.map(&:record_type)).to eq([:split_time] * records.size)
          expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, 2581.36, 6308.86, 9463.56, 13571.37, 16655.3, 17736.43])
        end

        it 'returns expected times_from_start array when some times are not present' do
          records = third_proto_record.children
          expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, 4916.63, 14398.48, nil, nil, nil, nil])
        end

        it 'returns times_from_start calculated by subtracting from finish time when middle segment times are missing' do
          records = second_proto_record.children
          expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, 3201.92, 8103.97, nil, 17977.92, 22233.88, 23565.84])
        end

        it 'marks records for destruction when time_from_start is not present' do
          records = third_proto_record.children
          expect(records.map { |pr| pr.record_action }).to eq([nil] * 3 + [:destroy] * 4)
        end

        it 'returns expected times_from_start array when no times are present' do
          records = last_proto_record.children
          expect(records.map { |pr| pr[:time_from_start] }).to eq([nil] * records.size)
        end

        it 'returns expected split_id array when no times are present' do
          records = last_proto_record.children
          time_points = event.required_time_points
          expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
        end

        it 'sets [:stopped_here] attribute on the final child record if [:time] == "DNF" or "DSQ"' do
          records = third_proto_record.children
          expect(records.reverse.find { |pr| pr[:time_from_start].present? }[:stopped_here]).to eq(true)
          expect(records.map { |pr| pr[:stopped_here] }).to eq([nil, nil, true, nil, nil, nil, nil])
          records = fourth_proto_record.children
          expect(records.reverse.find { |pr| pr[:time_from_start].present? }[:stopped_here]).to eq(true)
          expect(records.map { |pr| pr[:stopped_here] }).to eq([nil, nil, true, nil, nil, nil, nil])
        end

        it 'does not set [:stopped_here] attribute if [:time] != "DNF"' do
          expect(first_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
          expect(second_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
          expect(last_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
        end
      end

      context 'when parsed_structs do not contain section splits and the provided event has only start and finish splits' do
        let(:event) { build_stubbed(:event_with_standard_splits, id: 1, splits_count: 2) }
        let(:options) { {event: event} }
        let(:proto_records) { subject.transform }
        let(:parsed_structs) { [
            OpenStruct.new(rr_id: '5', place: '3', bib: '5', name: 'Jatest Schtest', sex: 'M', age: '39',
                           div_place: '3/10', sex_place: '3/50', time: '4:55:36.43', pace: '09:30'),
            OpenStruct.new(rr_id: '327', place: '67', bib: '327', name: 'Sutest Ritest', sex: 'F', age: '46',
                           div_place: '1/25', sex_place: '2/75', time: '6:32:45.84', pace: '12:38'),
            OpenStruct.new(rr_id: '661', place: '*', bib: '661', name: 'Castest Pertest', sex: 'F', age: '31',
                           div_place: '*', sex_place: '*', time: 'DNF', pace: '*'),
            OpenStruct.new(rr_id: '662', place: '*', bib: '662', name: 'Bestest Sartest', sex: 'M', age: '31',
                           div_place: '*', sex_place: '*', time: 'DSQ', pace: '*'),
            OpenStruct.new(rr_id: '633', place: '*', bib: '633', name: 'Mictest Hintest', sex: 'F', age: '35',
                           div_place: '*', sex_place: '*', time: 'DNS', pace: '*'),
            OpenStruct.new(rr_id: '62', place: '*', bib: '62', name: 'N.n. 62', sex: '', age: 'n/a',
                           div_place: '*', sex_place: '*', time: '', pace: '*')
        ] }

        it 'does not raise an error' do
          expect(subject.errors).to be_empty
        end

        it 'attaches child records for start and finish splits only' do
          records = first_proto_record.children
          time_points = event.required_time_points
          expect(records.size).to eq(2)
          expect(records.map(&:record_type)).to eq([:split_time] * records.size)
          expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, 17736.43])
        end

        it 'returns expected times_from_start array when the record is DNF' do
          records = third_proto_record.children
          expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, nil])
        end

        it 'returns expected times_from_start array when the record is DSQ' do
          records = fourth_proto_record.children
          expect(records.map { |pr| pr[:time_from_start] }).to eq([0.0, nil])
        end

        it 'returns expected times_from_start array when the record is DNS' do
          records = fifth_proto_record.children
          expect(records.map { |pr| pr[:time_from_start] }).to eq([nil, nil])
        end
      end
    end

    context 'when an event is not provided' do
      let(:event) { nil }
      let(:options) { {} }
      let(:parsed_structs) { [OpenStruct.new(rr_id: '5', place: '3', bib: '5', name: 'Jatest Schtest', sex: 'M', age: '39',
                                             section1_split: '0:43:01.36', section4_split: '1:08:27.81', section5_split: '0:51:23.93',
                                             section2_split: '1:02:07.50', section3_split: '0:52:34.70', section6_split: '0:18:01.15',
                                             elapsed: '4:55:36.43', time: '4:55:36.43', pace: '09:30')] }

      it 'returns nil and adds an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Event is missing/)
      end
    end

    context 'when event time_points do not match the provided segment times' do
      before do
        _, time_points = lap_splits_and_time_points(event)
        allow(event).to receive(:required_time_points).and_return(time_points)
      end

      let(:event) { build_stubbed(:event_with_standard_splits, id: 1, in_sub_splits_only: true, splits_count: 6) }
      let(:parsed_structs) { [OpenStruct.new(rr_id: '5', place: '3', bib: '5', name: 'Jatest Schtest', sex: 'M', age: '39',
                                             section1_split: '0:43:01.36', section4_split: '1:08:27.81', section5_split: '0:51:23.93',
                                             section2_split: '1:02:07.50', section3_split: '0:52:34.70', section6_split: '0:18:01.15',
                                             elapsed: '4:55:36.43', time: '4:55:36.43', pace: '09:30')] }


      it 'returns nil and adds an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Split mismatch error/)
      end
    end
  end
end
