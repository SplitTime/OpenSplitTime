require 'rails_helper'

RSpec.describe ETL::Transformers::EffortsWithTimesStrategy do
  subject { ETL::Transformers::EffortsWithTimesStrategy.new(structs, options) }
  let(:options) { {event: event} }
  let(:proto_records) { subject.transform }
  let(:complete_proto_record) { proto_records.first }
  let(:incomplete_proto_record) { proto_records.second }
  let(:offset_proto_record) { proto_records.third }
  let(:dnf_proto_record) { proto_records.fourth }
  let(:dns_proto_record) { proto_records.last }
  let(:children) { subject_proto_record.children }

  describe '#transform' do
    context 'when event is present and splits count matches split fields count' do
      before do
        _, time_points = lap_splits_and_time_points(event)
        allow(event).to receive(:required_time_points).and_return(time_points)
      end

      context 'when the parsed structs contain multiple splits' do
        let(:structs) { [OpenStruct.new(Overall_rank: 10, Gender_rank: 10, First_name: 'Chris', Last_name: 'Dickey', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                        Start_Offset: '00:00:00',
                                        Dry_Fork_Outbound_In: '02:48:54', Dry_Fork_Outbound_Out: '02:50:19',
                                        Jaws_In: '10:34:03', Jaws_Out: '10:43:20',
                                        Dry_Fork_Inbound_In: '19:18:39', Dry_Fork_Inbound_Out: '19:28:24',
                                        Finish: '22:24:07'),

                         OpenStruct.new(Overall_rank: 2, Gender_rank: 2, First_name: 'Patrick', Last_name: 'McGlade', Gender: 'male', Age: 25, State_code: 'CO', Country_code: 'US',
                                        Start_Offset: '00:00:00',
                                        Dry_Fork_Outbound_In: '', Dry_Fork_Outbound_Out: '',
                                        Jaws_In: '09:40:24', Jaws_Out: '09:50:46',
                                        Dry_Fork_Inbound_In: '16:48:36', Dry_Fork_Inbound_Out: '16:48:42',
                                        Finish: '19:39:02'),

                         OpenStruct.new(Overall_rank: 99, Gender_rank: 99, First_name: 'Bob', Last_name: 'Cratchett', Gender: 'male', Age: 43, State_code: 'CO', Country_code: 'US',
                                        Start_Offset: '-00:30:00',
                                        Dry_Fork_Outbound_In: '02:48:54', Dry_Fork_Outbound_Out: '02:50:19',
                                        Jaws_In: '10:34:03', Jaws_Out: '10:43:20',
                                        Dry_Fork_Inbound_In: '19:18:39', Dry_Fork_Inbound_Out: '19:28:24',
                                        Finish: '22:24:07'),

                         OpenStruct.new(Overall_rank: 254, Gender_rank: 213, First_name: 'Michael', Last_name: "O'Connor", Gender: 'male', Age: 40, State_code: 'IL', Country_code: 'US',
                                        Start_Offset: '00:00:00',
                                        Dry_Fork_Outbound_In: '02:46:23', Dry_Fork_Outbound_Out: '02:47:44',
                                        Jaws_In: '', Jaws_Out: '',
                                        Dry_Fork_Inbound_In: '', Dry_Fork_Inbound_Out: '',
                                        Finish: ''),

                         OpenStruct.new(Overall_rank: 255, Gender_rank: 214, First_name: 'Michael', Last_name: 'Vasti', Gender: 'male', Age: 38, State_code: 'NY', Country_code: 'US',
                                        Start_Offset: '',
                                        Dry_Fork_Outbound_In: '', Dry_Fork_Outbound_Out: '',
                                        Jaws_In: '', Jaws_Out: '',
                                        Dry_Fork_Inbound_In: '', Dry_Fork_Inbound_Out: '',
                                        Finish: '')
        ] }

        let(:event) { build_stubbed(:event_with_standard_splits, id: 1, splits_count: 5) }

        it 'returns the same number of ProtoRecords as it is given OpenStructs' do
          expect(proto_records.size).to eq(structs.size)
          expect(proto_records).to all be_a(ProtoRecord)
        end

        it 'returns rows with effort headers transformed to match the database' do
          keys = complete_proto_record.to_h.keys
          %i(age event_id first_name gender last_name state_code country_code).each do |expected_key|
            expect(keys).to include(expected_key)
          end
        end

        it 'assigns event.id to :event_id key' do
          expect(proto_records.map { |pr| pr[:event_id] }).to all eq(event.id)
        end

        context 'for a complete proto_record' do
          let(:subject_proto_record) { complete_proto_record }

          it 'sorts split headers and returns an array of children' do
            time_points = event.required_time_points
            expect(children.size).to eq(8)
            expect(children.map(&:record_type)).to all eq(:split_time)
            expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
            expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
            expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
            expect(children.map { |pr| pr[:time_from_start] }).to eq([0, 10134, 10219, 38043, 38600, 69519, 70104, 80647])
          end
        end

        context 'for an incomplete proto_record' do
          let(:subject_proto_record) { incomplete_proto_record }

          it 'returns an expected array of children' do
            time_points = event.required_time_points[0..0] + event.required_time_points[3..-1]
            expect(children.size).to eq(6)
            expect(children.map(&:record_type)).to all eq(:split_time)
            expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
            expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
            expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
            expect(children.map { |pr| pr[:time_from_start] }).to eq([0, 34824, 35446, 60516, 60522, 70742])
          end
        end

        context 'for a proto_record whose start split_time is not zero' do
          let(:subject_proto_record) { offset_proto_record }

          it 'sets effort offset and sets start split_time to zero' do
            time_points = event.required_time_points
            expect(children.size).to eq(8)
            expect(children.map(&:record_type)).to all eq(:split_time)
            expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
            expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
            expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
            expect(children.map { |pr| pr[:time_from_start] }).to eq([0, 10134, 10219, 38043, 38600, 69519, 70104, 80647])
            expect(subject_proto_record[:start_offset]).to eq(-1800)
          end
        end

        context 'for a proto_record with no finish time' do
          let(:subject_proto_record) { dnf_proto_record }

          it 'returns an array of children correctly' do
            time_points = event.required_time_points.first(3)
            expect(children.size).to eq(3)
            expect(children.map(&:record_type)).to all eq(:split_time)
            expect(children.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
            expect(children.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
            expect(children.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
            expect(children.map { |pr| pr[:time_from_start] }).to eq([0, 9983, 10064])
          end

          it 'sets [:stopped_here] attribute on the final child record' do
            expect(children.map { |pr| pr[:stopped_here] }).to eq([nil, nil, true])
          end
        end

        context 'for a proto_record that has no times' do
          let(:subject_proto_record) { dns_proto_record }

          it 'returns an empty array of child records' do
            children = dns_proto_record.children
            expect(children.size).to eq(0)
          end
        end
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

    context 'when event time_points do not match the provided segment times' do
      before do
        _, time_points = lap_splits_and_time_points(event)
        allow(event).to receive(:required_time_points).and_return(time_points)
      end

      let(:event) { build_stubbed(:event_with_standard_splits, id: 1, in_sub_splits_only: true, splits_count: 2) }
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
