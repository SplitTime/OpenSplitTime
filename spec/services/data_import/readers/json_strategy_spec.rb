RSpec.describe DataImport::Readers::JsonStrategy do
  subject { DataImport::Readers::JsonStrategy.new(json_blob) }

  describe '#read_file' do
    context 'when json_blob is valid_json' do
      let(:file_path) { "#{Rails.root}/spec/fixtures/files/test_rr_response.json" }
      let(:json_blob) { File.read(file_path) }

      it 'returns the provided json_blob converted to a hash' do
        raw_data = subject.read_file
        expect(raw_data).to be_a(Hash)
        expect(raw_data['list']['Fields'].size).to eq(14)
      end
    end

    context 'when json_blob is a blank string' do
      let(:json_blob) { '' }

      it 'returns nil and adds an error to the errors array' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/Data not present/)
      end
    end

    context 'when json_blob is not valid json' do
      let(:json_blob) { '{' }

      it 'returns nil and adds an error to the errors array' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/Invalid JSON/)
      end
    end

    context 'when json_blob is nil' do
      let(:json_blob) { nil }

      it 'returns nil and adds an error to the errors array' do
        raw_data = subject.read_file
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/Data not present/)
      end
    end
  end
end
