require 'rails_helper'

RSpec.describe ETL::Transformers::JsonapiBatchStrategy do
  subject { ETL::Transformers::JsonapiBatchStrategy.new(parsed_structs, options) }

  let(:course) { build_stubbed(:course, id: 10) }
  let(:event) { build_stubbed(:event, id: 1, course: course) }
  let(:options) { { parent: event } }
  let(:proto_records) { subject.transform }
  let(:clean_parsed_structs) { [
    OpenStruct.new(type: 'raw_time',
                   attributes: { 'bibNumber' => '101', 'splitName' => 'Aid 1', 'bitkey' => 1,
                                 'absoluteTime' => '10:45:45-06:00', 'withPacer' => true, 'stoppedHere' => false }),
    OpenStruct.new(type: 'raw_time',
                   attributes: { 'bibNumber' => '101', 'splitName' => 'Aid 1', 'bitkey' => 64,
                                 'absoluteTime' => '10:45:45-06:00', 'withPacer' => true, 'stoppedHere' => true }),
  ] }
  let(:dirty_parsed_structs) { [
    OpenStruct.new(type: 'raw_time',
                   attributes: { 'bibNumber' => '101', 'splitName' => 'Aid 1', 'name_extension' => 'in',
                                 'absoluteTime' => '10:45:45-06:00', 'withPacer' => true, 'stoppedHere' => false }),
  ] }
  let(:first_proto_record) { proto_records.first }
  let(:second_proto_record) { proto_records.second }

  describe '#transform' do
    context 'when data is all valid and keys match database fields' do
      let(:parsed_structs) { clean_parsed_structs }

      it 'returns the same number of ProtoRecords as it is given OpenStructs' do
        expect(proto_records.size).to eq(2)
        expect(proto_records).to all(be_a(ProtoRecord))
      end

      it 'sets the record_type based on the provided type' do
        expect(proto_records.map(&:record_type)).to all(eq(:raw_time))
      end

      it 'moves all attributes into the ProtoRecord attributes struct' do
        expect(first_proto_record.to_h.keys)
          .to match_array(%i(absolute_time bib_number bitkey split_name stopped_here with_pacer))
      end
    end

    context 'when data is all valid but some keys do not match database fields' do
      let(:parsed_structs) { dirty_parsed_structs }

      it 'returns the same number of ProtoRecords as it is given OpenStructs' do
        expect(proto_records.size).to eq(1)
        expect(proto_records).to all(be_a(ProtoRecord))
      end

      it 'converts name_extension to the applicable bitkey' do
        expect(first_proto_record[:bitkey]).to eq(1)
      end
    end

    context 'when an effort with scheduled start offset is provided' do
      let(:parsed_structs) { [
        OpenStruct.new(
          { :type => "efforts",
            :attributes =>
              { "first_name" => "Schuyler",
                "last_name" => "Argon",
                "scheduled_start_offset" => "900" } }
        )
      ] }

      it 'returns a ProtoRecord having expected attributes' do
        expect(proto_records.size).to eq(1)
        expect(first_proto_record[:first_name]).to eq('Schuyler')
        expect(first_proto_record[:scheduled_start_offset]).to eq("900")
      end
    end
  end
end
