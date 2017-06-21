require 'rails_helper'

include ActionDispatch::TestProcess

RSpec.describe DataImport::Readers::CsvFileStrategy do
  subject { DataImport::Readers::CsvFileStrategy.new(file) }

  describe '#read_file' do
    context 'when file is provided' do
      let(:file) { File.new("#{Rails.root}/spec/fixtures/files/test_efforts.csv") }

      it 'returns raw data in hash format' do
        raw_data = subject.read_file
        expect(raw_data.size).to eq(3)
        expect(raw_data.all? { |row| row.is_a?(Hash) }).to eq(true)
      end
    end

    context 'when file is not provided' do
      let(:file) { nil }

      it 'returns nil' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/File not found/)
      end
    end

    context 'when the file has non-standard characters in headers' do
      let(:file) { File.new("#{Rails.root}/spec/fixtures/files/test_efforts_header_formats.csv") }

      it 'returns headers converted to symbols' do
        raw_data = subject.read_file
        expect(raw_data.first.keys).to eq([:first_name, :LAST, :sex, :age, :city, :state, :country, :"bib_#"])
      end
    end
  end
end
