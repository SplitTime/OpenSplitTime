require 'rails_helper'

include ActionDispatch::TestProcess

RSpec.describe DataImport::Readers::JsonStrategy do
  subject { DataImport::Readers::JsonStrategy.new(data_object) }

  describe '#read_file' do
    context 'when data_object is a json blob' do
      let(:file_path) { "#{Rails.root}/spec/fixtures/files/test_rr_response.json" }
      let(:data_object) { File.read(file_path) }

      it 'returns the provided data_object converted to a hash' do
        raw_data = subject.read_file
        expect(raw_data).to be_a(Hash)
        expect(raw_data['list']['Fields'].size).to eq(14)
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
