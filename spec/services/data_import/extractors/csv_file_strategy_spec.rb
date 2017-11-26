RSpec.describe DataImport::Extractors::CsvFileStrategy do
  subject { DataImport::Extractors::CsvFileStrategy.new(file, options) }
  let(:options) { {} }

  describe '#extract' do
    context 'when file is provided' do
      let(:file) { File.new("#{Rails.root}/spec/fixtures/files/test_efforts.csv") }

      it 'returns raw data in OpenStruct format' do
        raw_data = subject.extract
        expect(raw_data.size).to eq(3)
        expect(raw_data).to all be_a(OpenStruct)
      end
    end

    context 'when file is not provided' do
      let(:file) { nil }

      it 'returns nil' do
        raw_data = subject.extract
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/File not found/)
      end
    end

    context 'when the file has non-standard characters in headers' do
      let(:file) { File.new("#{Rails.root}/spec/fixtures/files/test_efforts_header_formats.csv") }

      it 'returns headers converted to symbols' do
        raw_data = subject.extract
        expect(raw_data.first.to_h.keys).to eq([:first_name, :last, :sex, :age, :city, :state, :country, :"bib_#"])
      end
    end
  end
end
