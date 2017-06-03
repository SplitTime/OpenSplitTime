require 'rails_helper'

include ActionDispatch::TestProcess

RSpec.describe DataImport::RaceResult::ReadStrategy do
  subject { DataImport::RaceResult::ReadStrategy.new(file_path) }

  describe '#read_file' do
    context 'when file_path is a hash' do
      let(:file_path) { {'list' => {'LastChange' => '2016-06-04 21:58:25'}} }

      it 'returns the provided hash in the same format as provided' do
        raw_data = subject.read_file
        expect(raw_data).to eq(file_path)
      end
    end

    context 'when file_path is not a Hash (and so assumed to be a file path)' do
      let(:file_path) { '/spec/fixtures/files/test_rr_response.json' }

      it 'reads the file and returns a parsed version in Hash format' do
        raw_data = subject.read_file
        expect(raw_data['list']['last_change']).to eq('2016-06-04 21:58:25')
      end
    end

    context 'when file_path is not a Hash and references a non-existent file' do
      let(:file_path) { '/non/existent/file' }

      it 'returns nil' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/File not found/)
      end
    end
  end
end
