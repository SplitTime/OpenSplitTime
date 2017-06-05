require 'rails_helper'

include ActionDispatch::TestProcess

RSpec.describe DataImport::Readers::HashStrategy do
  subject { DataImport::Readers::HashStrategy.new(data_object) }

  describe '#read_file' do
    context 'when data_object is a hash' do
      let(:data_object) { {'list' => {'LastChange' => '2016-06-04 21:58:25'}} }

      it 'returns the provided hash in the same format as provided' do
        raw_data = subject.read_file
        expect(raw_data).to eq(data_object)
      end
    end

    context 'when data_object is nil' do
      let(:data_object) { nil }

      it 'returns nil and adds an error to the errors array' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/Data not present/)
      end
    end
  end
end
