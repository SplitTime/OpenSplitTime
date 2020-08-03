# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ETL::Transformers::EffortsWithTimesStrategy do
  subject { ETL::Transformers::EffortsWithTimesStrategy.new(structs, options) }
  let(:options) { {parent: event} }
  let(:proto_records) { subject.transform }
  let(:keys) { proto_records.first.to_h.keys }
  let(:children) { subject_proto_record.children }
  let(:time_points) { event.required_time_points }
  let(:start_time) { event.start_time }

  describe '#transform' do
    context 'when given valid data using elapsed times' do
      let(:event) { events(:ggd30_50k) }

      let(:structs) { [OpenStruct.new(Overall_rank: 10, Gender_rank: 10, First_name: 'Chris', Last_name: 'Dickey', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Start_Offset: '00:00:00',
                                      Dry_Fork_Outbound_In: '02:48:54', Dry_Fork_Outbound_Out: '02:50:19',
                                      Jaws_In: '10:34:03', Jaws_Out: '10:43:20',
                                      Dry_Fork_Inbound_In: '19:18:39',
                                      Finish: '22:24:07'),

                       OpenStruct.new(Overall_rank: 2, Gender_rank: 2, First_name: 'Patrick', Last_name: 'McGlade', Gender: 'male', Age: 25, State_code: 'CO', Country_code: 'US',
                                      Start_Offset: '00:00:00',
                                      Dry_Fork_Outbound_In: '', Dry_Fork_Outbound_Out: '',
                                      Jaws_In: '09:40:24', Jaws_Out: '09:50:46',
                                      Dry_Fork_Inbound_In: '16:48:36',
                                      Finish: '19:39:02'),

                       OpenStruct.new(Overall_rank: 99, Gender_rank: 99, First_name: 'Bob', Last_name: 'Cratchett', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Start_Offset: '-00:30:00',
                                      Dry_Fork_Outbound_In: '02:48:54', Dry_Fork_Outbound_Out: '02:50:19',
                                      Jaws_In: '10:34:03', Jaws_Out: '10:43:20',
                                      Dry_Fork_Inbound_In: '19:18:39',
                                      Finish: '22:24:07'),

                       OpenStruct.new(Overall_rank: 254, Gender_rank: 213, First_name: 'Michael', Last_name: "O'Connor", Gender: 'male', Age: 40, State_code: 'IL', Country_code: 'US',
                                      Start_Offset: '00:00:00',
                                      Dry_Fork_Outbound_In: '02:46:23', Dry_Fork_Outbound_Out: '02:47:44',
                                      Jaws_In: '', Jaws_Out: '',
                                      Dry_Fork_Inbound_In: '',
                                      Finish: ''),

                       OpenStruct.new(Overall_rank: 255, Gender_rank: 214, First_name: 'Michael', Last_name: 'Vasti', Gender: 'male', Age: 38, State_code: 'NY', Country_code: 'US',
                                      Start_Offset: '',
                                      Dry_Fork_Outbound_In: '', Dry_Fork_Outbound_Out: '',
                                      Jaws_In: '', Jaws_Out: '',
                                      Dry_Fork_Inbound_In: '',
                                      Finish: '')
      ] }

      it 'returns proto_records, assigns event_id, and returns correct keys' do
        expect(proto_records.size).to eq(structs.size)
        expect(proto_records).to all be_a(ProtoRecord)

        %i(age event_id first_name gender last_name state_code country_code).each do |expected_key|
          expect(keys).to include(expected_key)
        end

        expect(proto_records.map { |pr| pr[:event_id] }).to all eq(event.id)
      end

      context 'for a complete proto_record' do
        let(:subject_proto_record) { proto_records.first }

        it 'returns an array of children with imposed_order attributes' do
          time_points = event.required_time_points
          expect(children.size).to eq(7)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:absolute_time] }).to eq([0, 10134, 10219, 38043, 38600, 69519, 80647].map { |e| start_time + e })
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 1, 2, 3, 4, 5, 6])
        end
      end

      context 'for an incomplete proto_record' do
        let(:subject_proto_record) { proto_records.second }

        it 'returns an expected array of children' do
          time_points = event.required_time_points[0..0] + event.required_time_points[3..-1]
          expect(children.size).to eq(5)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:absolute_time] }).to eq([0, 34824, 35446, 60516, 70742].map { |e| start_time + e })
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 3, 4, 5, 6])
        end
      end

      context 'for a proto_record with no finish time' do
        let(:subject_proto_record) { proto_records.fourth }

        it 'returns an array of children correctly and sets [:stopped_here] attribute' do
          time_points = event.required_time_points.first(3)
          expect(children.size).to eq(3)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:absolute_time] }).to eq([0, 9983, 10064].map { |e| start_time + e })
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 1, 2])
          expect(children.map { |pr| pr[:stopped_here] }).to eq([nil, nil, true])
        end
      end

      context 'for a proto_record that has no times' do
        let(:subject_proto_record) { proto_records.fifth }

        it 'returns an empty array of child records' do
          expect(children.size).to eq(0)
        end
      end
    end

    context 'when given valid data using military times' do
      let(:event) { events(:rufa_2016) }
      before { event.update(laps_required: 1) }
      let(:options) { {parent: event, time_format: :military} }
      let(:structs) { [OpenStruct.new(Overall_rank: 10, Gender_rank: 10, First_name: 'Chris', Last_name: 'Dickey', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Start: '10:00:00',
                                      Jaws_In: '20:34:03',
                                      Finish: '08:24:07'),

                       OpenStruct.new(Overall_rank: 2, Gender_rank: 2, First_name: 'Patrick', Last_name: 'McGlade', Gender: 'male', Age: 25, State_code: 'CO', Country_code: 'US',
                                      Start: '10:00:00',
                                      Jaws_In: '19:40:24',
                                      Finish: '05:39:02'),

                       OpenStruct.new(Overall_rank: 99, Gender_rank: 99, First_name: 'Bob', Last_name: 'Cratchett', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Start: '09:30:00',
                                      Jaws_In: '20:34:03',
                                      Finish: '22:24:07'),

                       OpenStruct.new(Overall_rank: 254, Gender_rank: 213, First_name: 'Michael', Last_name: "O'Connor", Gender: 'male', Age: 40, State_code: 'IL', Country_code: 'US',
                                      Start: '10:00:00',
                                      Jaws_In: '',
                                      Finish: ''),

                       OpenStruct.new(Overall_rank: 255, Gender_rank: 214, First_name: 'Michael', Last_name: 'Vasti', Gender: 'male', Age: 38, State_code: 'NY', Country_code: 'US',
                                      Start: '',
                                      Jaws_In: '',
                                      Finish: '')
      ] }

      it 'returns proto_records, assigns event_id, and returns correct keys' do
        expect(proto_records.size).to eq(structs.size)
        expect(proto_records).to all be_a(ProtoRecord)

        %i(age event_id first_name gender last_name state_code country_code).each do |expected_key|
          expect(keys).to include(expected_key)
        end

        expect(proto_records.map { |pr| pr[:event_id] }).to all eq(event.id)
      end

      context 'for a complete proto_record' do
        let(:subject_proto_record) { proto_records.first }

        it 'returns an array of children' do
          time_points = event.required_time_points
          expect(children.size).to eq(3)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:military_time] }).to eq(%w(10:00:00 20:34:03 08:24:07))
          expect(children.map { |pr| pr[:absolute_time] }).to all be_nil
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 1, 2])
        end
      end
    end

    context 'when given only finish times' do
      let(:event) { events(:ramble) }
      let(:options) { {parent: event, time_format: :elapsed} }
      let(:structs) { [OpenStruct.new(Overall_rank: 10, Gender_rank: 10, First_name: 'Chris', Last_name: 'Dickey', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Finish: '0:20:05'),
                       OpenStruct.new(Overall_rank: 99, Gender_rank: 99, First_name: 'Bob', Last_name: 'Cratchett', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Finish: '1:00:10'),
                       OpenStruct.new(Overall_rank: 254, Gender_rank: 213, First_name: 'Michael', Last_name: "O'Connor", Gender: 'male', Age: 40, State_code: 'IL', Country_code: 'US',
                                      Finish: '')
      ] }

      it 'does not raise an error' do
        expect { subject.transform }.not_to raise_error
      end

      it 'transforms without error' do
        subject.transform
        expect(subject.errors).to be_empty
      end

      it 'returns proto_records, assigns event_id, and returns correct keys' do
        expect(proto_records.size).to eq(structs.size)
        expect(proto_records).to all be_a(ProtoRecord)

        %i(age event_id first_name gender last_name state_code country_code).each do |expected_key|
          expect(keys).to include(expected_key)
        end

        expect(proto_records.map { |pr| pr[:event_id] }).to all eq(event.id)
      end

      context 'for a complete proto_record' do
        let(:subject_proto_record) { proto_records.first }

        it 'returns an array of children with expected attributes' do
          time_points = event.required_time_points
          expect(children.size).to eq(2)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 1])
        end

        it 'assigns time attributes properly' do
          expect(children.map { |pr| pr[:absolute_time] }).to eq([0, 1205].map { |e| start_time + e })
        end
      end

      context 'for another complete proto_record' do
        let(:subject_proto_record) { proto_records.second }

        it 'assigns time attributes properly' do
          expect(children.map { |pr| pr[:absolute_time] }).to eq([0, 3610].map { |e| start_time + e })
        end
      end

      context 'for a proto record that has no finish time' do
        let(:subject_proto_record) { proto_records.last }
        it 'does not assign a start or finish time' do
          expect(children.size).to eq(0)
        end
      end
    end

    context 'when an event has unlimited laps' do
      let(:options) { {parent: event} }
      let(:event) { events(:rufa_2016) }
      let(:structs) { [
          OpenStruct.new(First_name: 'Patrick', Last_name: 'McGlade', Gender: 'male', Age: 25, State_code: 'CO', Country_code: 'US',
                         Start_lap_1: '00:00:00', Aid_lap_1: '09:40:24', Finish_lap_1: '15:39:02',
                         Start_lap_2: '16:00:00', Aid_lap_2: '20:00:00', Finish_lap_2: '23:59:59'),

          OpenStruct.new(First_name: 'Patricia', Last_name: 'McOwens', Gender: 'female', Age: 22, State_code: 'NY', Country_code: 'US',
                         Start_lap_1: '00:00:00', Aid_lap_1: '', Finish_lap_1: '15:00:00',
                         Start_lap_2: '', Aid_lap_2: '', Finish_lap_2: '20:01:01'),

          OpenStruct.new(First_name: 'Bob', Last_name: 'Cratchett', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                         Start_lap_1: '01:00:00', Aid_lap_1: '08:40:24', Finish_lap_1: '13:39:02',
                         Start_lap_2: '14:00:00', Aid_lap_2: '18:00:00', Finish_lap_2: '')
      ] }

      it 'returns proto_records, assigns event_id, and returns correct keys' do
        expect(proto_records.size).to eq(structs.size)
        expect(proto_records).to all be_a(ProtoRecord)

        %i(age event_id first_name gender last_name state_code country_code).each do |expected_key|
          expect(keys).to include(expected_key)
        end

        expect(proto_records.map { |pr| pr[:event_id] }).to all eq(event.id)
      end

      context 'for a complete proto_record' do
        let(:subject_proto_record) { proto_records.first }

        it 'returns an array of children' do
          time_points = event.time_points_through(2)
          expect(children.size).to eq(6)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:absolute_time] }).to eq([0, 34824, 56342, 57600, 72000, 86399].map { |e| start_time + e })
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 1, 2, 3, 4, 5])
        end
      end

      context 'for an incomplete proto_record' do
        let(:subject_proto_record) { proto_records.second }

        it 'returns an array of children' do
          complete_time_points = event.time_points_through(2)
          time_points = [complete_time_points.first, complete_time_points.third, complete_time_points.last]
          expect(children.size).to eq(3)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:absolute_time] }).to eq([0, 54000, 72061].map { |e| start_time + e })
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 2, 5])
        end
      end

      context 'for a dnf proto_record' do
        let(:subject_proto_record) { proto_records.third }

        it 'returns an array of children' do
          time_points = event.time_points_through(2).first(5)
          expect(children.size).to eq(5)
          expect(children.map(&:record_type)).to all eq(:split_time)
          expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(children.map { |pr| pr[:absolute_time] }).to eq([3600, 31224, 49142, 50400, 64800].map { |e| start_time + e })
          expect(children.map { |pr| pr[:imposed_order] }).to eq([0, 1, 2, 3, 4])
        end
      end
    end

    context 'when an unpermitted time_format is provided' do
      let(:structs) { [OpenStruct.new(Overall_rank: 10, Gender_rank: 10, First_name: 'Chris', Last_name: 'Dickey', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Start_Offset: '00:00:00',
                                      Finish: '22:24:07')] }
      let(:options) { {parent: event, time_format: :random_format} }
      let(:event) { events(:ramble) }

      it 'returns an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Argument value is not permitted/)
      end
    end

    context 'when no structs are provided' do
      let(:structs) { [] }
      let(:options) { {parent: event} }
      let(:event) { events(:ramble) }

      it 'returns an empty array of proto_records without returning an error' do
        expect(proto_records).to eq([])
        expect(subject.errors).to eq([])
      end
    end

    context 'when an event is not provided' do
      let(:event) { nil }
      let(:structs) { [OpenStruct.new(Overall_rank: 10, Gender_rank: 10, First_name: 'Chris', Last_name: 'Dickey', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Start_Offset: '00:00:00',
                                      Dry_Fork_Outbound_In: '02:48:54', Dry_Fork_Outbound_Out: '02:50:19',
                                      Jaws_In: '10:34:03', Jaws_Out: '10:43:20',
                                      Dry_Fork_Inbound_In: '19:18:39', Dry_Fork_Inbound_Out: '19:28:24',
                                      Finish: '22:24:07')] }

      it 'returns nil and adds an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Event is missing/)
      end
    end

    context 'when time_points for a fixed-lap event do not match the provided times' do
      let(:event) { events(:ramble) }
      let(:structs) { [OpenStruct.new(Overall_rank: 10, Gender_rank: 10, First_name: 'Chris', Last_name: 'Dickey', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                      Start_Offset: '00:00:00',
                                      Dry_Fork_Outbound_In: '02:48:54', Dry_Fork_Outbound_Out: '02:50:19',
                                      Jaws_In: '10:34:03', Jaws_Out: '10:43:20',
                                      Dry_Fork_Inbound_In: '19:18:39', Dry_Fork_Inbound_Out: '19:28:24',
                                      Finish: '22:24:07')] }

      it 'returns nil and adds an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Split mismatch error/)
      end
    end
  end
end
