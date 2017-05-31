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

  describe '#attribute_rows' do
    it 'returns an array of objects having attributes contained in the file' do
      parser = CsvParser.new(file_path: file_path, model: :efforts)
      expect(parser.attribute_rows.size).to eq(3)
      expect(parser.attribute_rows.map { |row| row[:effort][:first_name]}).to eq(%w(Bjorn Charlie Lucy))
    end

    it 'maps header keys as specified in the class parameters file' do
      parser = CsvParser.new(file_path: header_test_file_path, model: :efforts)
      expect(parser.attribute_rows.size).to eq(1)
      row = parser.attribute_rows.first
      expected = {effort: {first_name: 'Lucy', last_name: 'Pendergrast', gender: 'female', age: 13,
                           city: 'Psych', state_code: 'OH', country_code: 'US', bib_number: 101}}.with_indifferent_access
      expect(row).to eq(expected)
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
