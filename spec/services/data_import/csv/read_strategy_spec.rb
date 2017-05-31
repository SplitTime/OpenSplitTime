require 'rails_helper'

include ActionDispatch::TestProcess

RSpec.describe DataImport::Csv::ReadStrategy do
  let(:file_path) { "/spec/fixtures/files/test_efforts.csv" }
  subject { DataImport::Csv::ReadStrategy.new(file_path) }

  describe '#read_file' do
    context 'when the file_path references an existing file' do
      it 'returns raw data in hash format' do
        raw_data = subject.read_file
        expect(raw_data.size).to eq(3)
        expect(raw_data.all? { |row| row.is_a?(Hash) }).to eq(true)
      end
    end

    context 'when the file_path references a non-existent file' do
      let(:file_path) { '/non/existent/file' }

      it 'returns nil' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/File not found/)
      end
    end
  end
end
