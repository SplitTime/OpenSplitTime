require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe CsvImporter do
  let(:file_path) { '/spec/fixtures/files/test_efforts.csv' }
  let(:mixed_records_file_path) { '/spec/fixtures/files/test_efforts_mixed.csv' }
  let(:header_test_file_path) { '/spec/fixtures/files/test_efforts_header_formats.csv' }
  let(:event) { create(:event) }
  let(:global_attributes) { {event: event} }

  describe '#initialization' do
    it 'initializes when provided with a file_path and a model' do
      expect { expect { CsvImporter.new(file_path: file_path, model: :efforts) }
      }
          .not_to raise_error
    end

    it 'raises an error if no file_path is provided' do
      expect { CsvImporter.new(file_path: nil, model: :efforts) }
          .to raise_error(/must include file_path/)
    end

    it 'raises an error if no model is provided' do
      expect { CsvImporter.new(file_path: file_path, model: nil) }
          .to raise_error(/must include model/)
    end
  end

  describe '#import' do
    it 'reads the specified file and creates records of the model type specified when all rows are valid' do
      importer = CsvImporter.new(file_path: file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(Effort.count).to eq(3)
      expect(Effort.all.pluck(:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end

    it 'reads the specified file and creates records of the model type specified when all rows are valid' do
      importer = CsvImporter.new(file_path: file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(Effort.count).to eq(3)
      expect(Effort.all.pluck(:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end

    it 'does not create any records if any row is invalid' do
      importer = CsvImporter.new(file_path: mixed_records_file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(Effort.count).to eq(0)
    end

    it 'maps header keys as specified in class parameters file' do
      importer = CsvImporter.new(file_path: header_test_file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(importer.valid_records.size).to eq(1)
      effort = importer.valid_records.first
      expect(effort.first_name).to eq('Lucy')
      expect(effort.last_name).to eq('Pendergrast')
      expect(effort.gender).to eq('female')
      expect(effort.state_code).to eq('OH')
      expect(effort.country_code).to eq('US')
    end

    context 'when provided with a unique key' do
      it 'updates matched records and creates unmatched records' do
        create(:effort, bib_number: 101, event: event)
        expected_first_names = %w(Bjorn Charlie Lucy)
        expect(Effort.count).to eq(1)
        expect(expected_first_names).not_to include(Effort.last.first_name)
        importer = CsvImporter.new(file_path: file_path, model: :efforts,
                                   global_attributes: global_attributes, unique_key: :bib_number)
        importer.import
        expect(Effort.count).to eq(3)
        expect(Effort.all.pluck(:first_name).sort).to eq(expected_first_names)
      end
    end
  end

  describe '#valid_records' do
    it 'returns the saved records' do
      importer = CsvImporter.new(file_path: file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      saved = importer.valid_records
      expect(saved.count).to eq(3)
      expect(saved.map(&:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end
  end

  describe '#invalid_records' do
    it 'returns the attributes of the rejected records' do
      importer = CsvImporter.new(file_path: mixed_records_file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(importer.invalid_records.count).to eq(2)
    end
  end

  describe 'response_status' do
    it 'returns :created when all records are valid' do
      importer = CsvImporter.new(file_path: file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(importer.response_status).to eq(:created)
    end

    it 'returns :unprocessable_entity when any record is invalid' do
      importer = CsvImporter.new(file_path: mixed_records_file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(importer.response_status).to eq(:unprocessable_entity)
    end
  end
end
