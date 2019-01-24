# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ETL::Transformers::RaceResultApiSplitTimesStrategy do
  subject { ETL::Transformers::RaceResultApiSplitTimesStrategy.new(parsed_structs, options) }
  let(:options) { {parent: event} }
  let(:proto_records) { subject.transform }
  let(:first_proto_record) { proto_records.first }
  let(:second_proto_record) { proto_records.second }
  let(:third_proto_record) { proto_records.third }
  let(:last_proto_record) { proto_records.last }

  describe '#transform' do
    let(:start_time) { event.start_time }

    context 'when event is present and splits count matches split fields count' do
      before do
        _, time_points = lap_splits_and_time_points(event)
        allow(event).to receive(:required_time_points).and_return(time_points)
      end

      let(:event) { build_stubbed(:event_with_standard_splits, start_time_local: '2018-10-31 07:00:00', in_sub_splits_only: true, splits_count: 7) }
      let(:time_points) { event.required_time_points }
      let(:parsed_structs) { [
          OpenStruct.new(time_0: '7:05:05 AM',
                         time_1: '8:05:19 AM',
                         time_2: '8:50:50 AM',
                         time_3: '9:37:57 AM',
                         time_4: '10:30:59 AM',
                         time_5: '11:11:22 AM',
                         time_6: '12:04:37 PM',
                         bib: '194',
                         status: 'OK',
                         rr_id: '194'),
          OpenStruct.new(time_0: '7:05:29 AM',
                         time_1: '8:11:19 AM',
                         time_2: '8:58:41 AM',
                         time_3: '9:45:39 AM',
                         time_4: '',
                         time_5: '11:22:34 AM',
                         time_6: '12:18:13 PM',
                         bib: '1065',
                         status: 'OK',
                         rr_id: '1065'),
          OpenStruct.new(time_0: '7:05:42 AM',
                         time_1: '8:22:41 AM',
                         time_2: '9:15:25 AM',
                         time_3: '10:07:56 AM',
                         time_4: '10:54:19 AM',
                         time_5: '',
                         time_6: '',
                         bib: '167',
                         status: 'DNF',
                         rr_id: '167'),
          OpenStruct.new(time_0: '',
                         time_1: '',
                         time_2: '',
                         time_3: '',
                         time_4: '',
                         time_5: '',
                         time_6: '',
                         bib: '250',
                         status: 'DNS',
                         rr_id: '250')
      ] }

      let(:expected_times) { times_with_zone(time_strings) }

      it 'returns the same number of ProtoRecords as it is given OpenStructs' do
        expect(proto_records.size).to eq(4)
        expect(proto_records.all? { |row| row.is_a?(ProtoRecord) }).to eq(true)
      end

      it 'returns rows with effort headers transformed to match the database' do
        expect(first_proto_record.to_h.keys).to match_array(%i(bib_number event_id))
      end

      it 'assigns event.id to :event_id key' do
        expect(proto_records.map { |pr| pr[:event_id] }).to all eq(event.id)
      end

      context 'when all times are present' do
        let(:records) { first_proto_record.children }
        let(:time_strings) { ['2018-10-31 07:05:05',
                              '2018-10-31 08:05:19',
                              '2018-10-31 08:50:50',
                              '2018-10-31 09:37:57',
                              '2018-10-31 10:30:59',
                              '2018-10-31 11:11:22',
                              '2018-10-31 12:04:37'] }

        it 'sorts split headers and returns an array of children' do
          expect(records.size).to eq(7)
          expect(records.map(&:record_type)).to eq([:split_time] * records.size)
          expect(records.map { |pr| pr[:lap] }).to eq(time_points.map(&:lap))
          expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          expect(records.map { |pr| pr[:sub_split_bitkey] }).to eq(time_points.map(&:bitkey))
          expect(records.map { |pr| pr[:absolute_time] }).to eq(expected_times)
        end
      end

      context 'when options[:delete_blank_times] is true' do
        let(:options) { {parent: event, delete_blank_times: true} }

        context 'when end times are not present' do
          let(:records) { third_proto_record.children }
          let(:time_strings) { ['2018-10-31 07:05:42',
                                '2018-10-31 08:22:41',
                                '2018-10-31 09:15:25',
                                '2018-10-31 10:07:56',
                                '2018-10-31 10:54:19',
                                nil,
                                nil] }
          it 'returns expected absolute_times array and marks blank records for destruction' do
            expect(records.size).to eq(7)
            expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
            expect(records.map { |pr| pr[:absolute_time] }).to eq(expected_times)
            expect(records.map(&:record_action)).to eq([nil] * 5 + [:destroy] * 2)
          end
        end

        context 'when middle segment times are missing' do
          let(:records) { second_proto_record.children }
          let(:time_strings) { ['2018-10-31 07:05:29',
                                '2018-10-31 08:11:19',
                                '2018-10-31 08:58:41',
                                '2018-10-31 09:45:39',
                                nil,
                                '2018-10-31 11:22:34',
                                '2018-10-31 12:18:13'] }

          it 'returns expected absolute_times' do
            expect(records.map { |pr| pr[:absolute_time] }).to eq(expected_times)
            expect(records.map(&:record_action)).to eq([nil] * 4 + [:destroy] + [nil] * 2)
          end
        end

        context 'when no times are present' do
          let(:records) { last_proto_record.children }
          let(:time_points) { event.required_time_points }

          it 'returns expected times_from_start array' do
            expect(records.map { |pr| pr[:absolute_time] }).to all eq(nil)
          end

          it 'returns expected split_id array when no times are present' do
            expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id))
          end
        end

        context 'when [:status] == "DNF" or "DSQ"' do
          let(:records) { third_proto_record.children }

          it 'sets [:stopped_here] attribute on the final child record' do
            expect(records.reverse.find { |pr| pr[:absolute_time].present? }[:stopped_here]).to eq(true)
            expect(records.map { |pr| pr[:stopped_here] }).to eq([nil, nil, nil, nil, true, nil, nil])
          end
        end

        context 'when [:status] is "OK" or "DNS"' do
          it 'does not set [:stopped_here] attribute' do
            expect(first_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
            expect(second_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
            expect(last_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
          end
        end
      end

      context 'when options[:delete_blank_times] is false' do
        let(:options) { {parent: event, delete_blank_times: false} }

        context 'when some times are not present' do
          let(:records) { third_proto_record.children }
          let(:time_strings) { ['2018-10-31 07:05:42',
                                '2018-10-31 08:22:41',
                                '2018-10-31 09:15:25',
                                '2018-10-31 10:07:56',
                                '2018-10-31 10:54:19'] }

          it 'returns expected absolute_times array' do
            expect(records.size).to eq(5)
            expect(records.map { |pr| pr[:split_id] }).to eq(time_points.map(&:split_id).first(5))
            expect(records.map { |pr| pr[:absolute_time] }).to eq(expected_times)
          end
        end

        context 'when no times are present' do
          let(:records) { last_proto_record.children }

          it 'creates no child records' do
            expect(records.size).to eq(0)
          end
        end

        context 'when [:status] == "DNF" or "DSQ"' do
          let(:records) { third_proto_record.children }

          it 'sets [:stopped_here] attribute on the final child record' do
            expect(records.reverse.find { |pr| pr[:absolute_time].present? }[:stopped_here]).to eq(true)
            expect(records.map { |pr| pr[:stopped_here] }).to eq([nil, nil, nil, nil, true])
          end
        end

        context 'when [:status] is "OK" or "DNS"' do
          it 'does not set [:stopped_here] attribute' do
            expect(first_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
            expect(second_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
            expect(last_proto_record.children.map { |pr| pr[:stopped_here] }).to all be_nil
          end
        end
      end
    end

    context 'when an event is not provided' do
      let(:event) { nil }
      let(:options) { {} }
      let(:parsed_structs) { [OpenStruct.new(time_0: '7:05:05 AM',
                                             time_1: '8:05:19 AM',
                                             time_2: '8:50:50 AM',
                                             time_3: '9:37:57 AM',
                                             time_4: '10:30:59 AM',
                                             time_5: '11:11:22 AM',
                                             time_6: '12:04:37 PM',
                                             bib: '194',
                                             status: 'OK',
                                             rr_id: '194')] }

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
      let(:parsed_structs) { [OpenStruct.new(time_0: '7:05:05 AM',
                                             time_1: '8:05:19 AM',
                                             time_2: '8:50:50 AM',
                                             time_3: '9:37:57 AM',
                                             time_4: '10:30:59 AM',
                                             bib: '194',
                                             status: 'OK',
                                             rr_id: '194')] }


      it 'returns nil and adds an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Split mismatch error/)
      end
    end

    def times_with_zone(time_strings)
      time_strings.map { |ts| ActiveSupport::TimeZone[event.home_time_zone].parse(ts) if ts }
    end
  end
end
