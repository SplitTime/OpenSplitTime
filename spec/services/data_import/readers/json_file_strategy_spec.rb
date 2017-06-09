require 'rails_helper'

include ActionDispatch::TestProcess

RSpec.describe DataImport::Readers::JsonFileStrategy do
  subject { DataImport::Readers::JsonFileStrategy.new(file_path) }

  describe '#read_file' do
    context 'when file_path references an existing file' do
      let(:file_path) { '/spec/fixtures/files/test_rr_response.json' }

      it 'reads the file and returns a parsed version in Hash format' do
        raw_data = subject.read_file
        expect(raw_data['list']['lastChange']).to eq('2016-06-04 21:58:25')
      end
    end

    context 'when file_path references a non-existent file' do
      let(:file_path) { '/non/existent/file' }

      it 'returns nil' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/File not found/)
      end
    end
  end
end
