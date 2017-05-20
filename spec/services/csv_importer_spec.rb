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

    context 'when provided with a unique key with existing data' do
      let(:file_path) { '/spec/fixtures/files/test_efforts_with_bib_numbers.csv' }
      let(:importer_params) { {file_path: file_path, model: :efforts, global_attributes: global_attributes,
                               unique_key: [:event_id, :bib_number]} }

      it 'updates matched records and creates unmatched records' do
        effort_same_event = create(:effort, bib_number: 101, event: event)
        effort_different_event = create(:effort, bib_number: 101)
        expect(Effort.count).to eq(2)
        expected_first_names = %w(Bjorn Charlie Lucy)
        expect(expected_first_names).not_to include(effort_same_event.first_name)
        importer = CsvImporter.new(importer_params)
        importer.import
        effort_different_event.reload
        expect(effort_different_event.changed?).to be_falsey
        expect(event.efforts.count).to eq(3)
        expect(event.efforts.pluck(:first_name).sort).to eq(expected_first_names)
      end
    end

    context 'when provided with a unique key where at least one field has no data' do
      let(:file_path) { '/spec/fixtures/files/test_efforts.csv' }
      let(:importer_params) { {file_path: file_path, model: :efforts, global_attributes: global_attributes,
                               unique_key: [:event_id, :bib_number]} }

      it 'does not match records but instead creates new records' do
        effort_same_event = create(:effort, bib_number: nil, event: event)
        expect(event.efforts.count).to eq(1)
        expected_first_names = %w(Bjorn Charlie Joe Lucy)
        importer = CsvImporter.new(importer_params)
        importer.import
        effort_same_event.reload
        expect(effort_same_event.changed?).to be_falsey
        expect(event.efforts.count).to eq(4)
        expect(event.efforts.pluck(:first_name).sort).to eq(expected_first_names)
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
