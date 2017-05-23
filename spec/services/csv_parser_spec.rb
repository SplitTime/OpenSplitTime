require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe CsvParser do
  let(:file_path) { '/spec/fixtures/files/test_efforts.csv' }
  let(:mixed_records_file_path) { '/spec/fixtures/files/test_efforts_mixed.csv' }
  let(:header_test_file_path) { '/spec/fixtures/files/test_efforts_header_formats.csv' }

  describe '#initialization' do
    it 'initializes when provided with a file_path and a model' do
      expect { CsvParser.new(file_path: file_path, model: :efforts) }
          .not_to raise_error
    end

    it 'raises an error if no file_path is provided' do
      expect { CsvParser.new(file_path: nil, model: :efforts) }
          .to raise_error(/must include file_path/)
    end

    it 'raises an error if no model is provided' do
      expect { CsvParser.new(file_path: file_path, model: nil) }
          .to raise_error(/must include model/)
    end
  end

  describe '#rows' do
    it 'returns an array of Structs having attributes contained in the file' do
      parser = CsvParser.new(file_path: file_path, model: :efforts)
      expect(parser.rows.size).to eq(3)
      expect(parser.rows.map(&:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end

    it 'maps header keys as specified in class parameters file' do
      parser = CsvParser.new(file_path: header_test_file_path, model: :efforts)
      expect(parser.rows.size).to eq(1)
      row = parser.rows.first
      expect(row.first_name).to eq('Lucy')
      expect(row.last_name).to eq('Pendergrast')
      expect(row.gender).to eq('female')
      expect(row.state_code).to eq('OH')
      expect(row.country_code).to eq('US')
    end

    describe '#errors' do
      it 'contains an error object when the file is not found' do
        parser = CsvParser.new(file_path: '/spec/fixtures/files/not_in_existence.csv', model: :efforts)
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:title]).to match(/File not found/)
      end
    end
  end
end
