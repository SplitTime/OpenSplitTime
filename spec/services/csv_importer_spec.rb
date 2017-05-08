require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe CsvImporter do
  let(:file_path) { "#{Rails.root}" + '/spec/fixtures/files/test_efforts.csv' }
  let(:event) { create(:event) }
  let(:global_attributes) { {event_id: event.id} }

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
    it 'reads the specified file and for valid rows creates records of the model type specified' do
      expect(Effort.count).to eq(0)
      importer = CsvImporter.new(file_path: file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(Effort.count).to eq(3)
      expect(Effort.all.pluck(:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end
  end

  describe '#saved_records' do
    it 'returns the saved records' do
      importer = CsvImporter.new(file_path: file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      saved = importer.saved_records
      expect(saved.count).to eq(3)
      expect(saved.map(&:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end
  end

  describe '#rejected_records' do
    let(:bad_records_file_path) { "#{Rails.root}" + '/spec/fixtures/files/test_efforts_bad.csv' }
    it 'returns the rejected records' do
      importer = CsvImporter.new(file_path: bad_records_file_path, model: :efforts, global_attributes: global_attributes)
      importer.import
      rejected = importer.rejected_records
      expect(rejected.count).to eq(3)
      expect(rejected.map(&:bib_number)).to eq([101, 202, 303])
    end
  end
end
