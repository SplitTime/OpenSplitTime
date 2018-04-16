require 'rails_helper'

RSpec.describe ETL::Transformers::CsvLiveTimesStrategy do
  subject { ETL::Transformers::CsvLiveTimesStrategy.new(parsed_structs, options) }

  let(:course) { build_stubbed(:course, id: 10) }
  let(:event) { build_stubbed(:event, id: 1, course: course) }
  let(:split) { build_stubbed(:split, course: course) }
  let(:proto_records) { subject.transform }
  let(:first_proto_record) { proto_records.first }
  let(:second_proto_record) { proto_records.second }
  let(:third_proto_record) { proto_records.third }
  let(:fourth_proto_record) { proto_records.fourth }

  describe '#transform' do
    context 'when data contains both in and out times' do
      let(:options) { {parent: event, split: split} }
      let(:parsed_structs) { [
          OpenStruct.new(bib_number: '101', time_in: '10:45', time_out: '10:50', pacer_in: true, pacer_out: true, stopped_here: false),
          OpenStruct.new(bib_number: '102', time_in: '14:10', time_out: '15:05', pacer_in: true, pacer_out: false, stopped_here: true)
      ] }

      it 'returns twice as many ProtoRecords as it is given OpenStructs' do
        expect(proto_records.size).to eq(4)
        expect(proto_records).to all(be_a(ProtoRecord))
      end

      it 'sets the record_type to :live_time' do
        expect(proto_records.map(&:record_type)).to all(eq(:live_time))
      end

      it 'moves all attributes into the ProtoRecord attributes struct' do
        expect(first_proto_record.to_h.keys.sort)
            .to eq(%i(bib_number bitkey event_id military_time split_id stopped_here with_pacer))
      end

      it 'creates proto_records having in or out bitkeys, as applicable' do
        expect(proto_records.map { |pr| pr[:bitkey] }).to eq([1, 64, 1, 64])
      end

      it 'assigns in_time and out_time to military_time attributes' do
        expect(proto_records.map { |pr| pr[:military_time] }).to eq(%w(10:45 10:50 14:10 15:05))
      end

      it 'assigns stopped_here as false to both related proto_records when the struct stopped_here is false' do
        expect(first_proto_record[:stopped_here]).to eq(false)
        expect(second_proto_record[:stopped_here]).to eq(false)
      end

      it 'assigns stopped_here as true to only the out proto_record when the struct stopped_here is true' do
        expect(third_proto_record[:stopped_here]).to eq(false)
        expect(fourth_proto_record[:stopped_here]).to eq(true)
      end
    end

    context 'when data contains only an in time or only an out time' do
      let(:options) { {parent: event, split: split} }
      let(:parsed_structs) { [
          OpenStruct.new(bib_number: '101', time_in: '10:45', time_out: '', pacer_in: true, stopped_here: false),
          OpenStruct.new(bib_number: '102', time_in: '', time_out: '15:05', pacer_out: false, stopped_here: true)
      ] }

      it 'returns the same number of ProtoRecords as it is given OpenStructs' do
        expect(proto_records.size).to eq(2)
        expect(proto_records).to all(be_a(ProtoRecord))
      end

      it 'sets the record_type to :live_time' do
        expect(proto_records.map(&:record_type)).to all(eq(:live_time))
      end

      it 'moves all attributes into the ProtoRecord attributes struct' do
        expect(first_proto_record.to_h.keys.sort)
            .to eq(%i(bib_number bitkey event_id military_time split_id stopped_here with_pacer))
      end

      it 'creates proto_records having in or out bitkeys, as applicable' do
        expect(proto_records.map { |pr| pr[:bitkey] }).to eq([1, 64])
      end

      it 'assigns in_time and out_time to military_time attributes' do
        expect(proto_records.map { |pr| pr[:military_time] }).to eq(%w(10:45 15:05))
      end
    end

    context 'when data contains no in or out time' do
      let(:options) { {parent: event, split: split} }
      let(:parsed_structs) { [
          OpenStruct.new(bib_number: '102', time_in: '', time_out: '', pacer_out: false, stopped_here: true)
      ] }

      it 'returns no proto_records' do
        expect(proto_records.size).to eq(0)
      end
    end

    context 'when no parent is provided' do
      let(:options) { {parent: nil, split: split} }
      let(:parsed_structs) { [
          OpenStruct.new(bib_number: '101', time_in: '10:45', time_out: '', pacer_in: true, stopped_here: false)
      ] }

      it 'returns no proto_records and includes an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Event is missing/)
      end
    end

    context 'when no split is provided' do
      let(:options) { {parent: event, split: nil} }
      let(:parsed_structs) { [
          OpenStruct.new(bib_number: '101', time_in: '10:45', time_out: '', pacer_in: true, stopped_here: false)
      ] }

      it 'returns no proto_records and includes an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Split is missing/)
      end
    end
  end
end
