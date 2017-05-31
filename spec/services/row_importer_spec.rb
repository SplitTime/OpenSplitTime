require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe RowImporter do
  let(:valid_rows) do
    [OpenStruct.new(first_name: 'Bjorn', last_name: 'Borg', gender: 'male', age: 37),
     OpenStruct.new(first_name: 'Charlie', last_name: 'Brown', gender: 'male', age: 13),
     OpenStruct.new(first_name: 'Lucy', last_name: 'Pendergrast', gender: 'female', age: 13)]
  end
  let(:mixed_rows) do
    [OpenStruct.new(first_name: 'Bjorn', last_name: 'Borg', gender: 'male', age: 37, city: 'Svendborg'),
     OpenStruct.new(first_name: 'Charlie', last_name: '', gender: 'male', age: 13, city: 'Peanuts', state_code: 'OH', country_code: 'US'),
     OpenStruct.new(first_name: 'Lucy', last_name: 'Pendergrast', gender: '', age: 13, city: 'Psych', state_code: 'OH', country_code: 'US')]
  end
  let(:event) { create(:event) }
  let(:global_attributes) { {event: event} }

  describe '#initialization' do
    it 'initializes when provided with rows and a model' do
      expect { RowImporter.new(rows: valid_rows, model: :efforts) }
          .not_to raise_error
    end

    it 'raises an error if no rows are provided' do
      expect { RowImporter.new(rows: nil, model: :efforts) }
          .to raise_error(/must include rows/)
    end

    it 'raises an error if no model is provided' do
      expect { RowImporter.new(rows: valid_rows, model: nil) }
          .to raise_error(/must include model/)
    end
  end

  describe '#import' do
    it 'creates records of the model type specified when all rows are valid' do
      importer = RowImporter.new(rows: valid_rows, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(Effort.count).to eq(3)
      expect(Effort.all.pluck(:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end

    it 'does not create any records if any row is invalid' do
      importer = RowImporter.new(rows: mixed_rows, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(Effort.count).to eq(0)
    end

    context 'when provided with a unique key with existing data' do
      let(:rows_with_bibs) do
        [OpenStruct.new(first_name: 'Bjorn', last_name: 'Borg', gender: 'male', age: 37, bib_number: 101),
         OpenStruct.new(first_name: 'Charlie', last_name: 'Brown', gender: 'male', age: 13, bib_number: 102),
         OpenStruct.new(first_name: 'Lucy', last_name: 'Pendergrast', gender: 'female', age: 13, bib_number: 103)]
      end
      let(:importer_params) { {rows: rows_with_bibs, model: :efforts, global_attributes: global_attributes,
                               unique_key: [:event_id, :bib_number]} }

      it 'updates matched records and creates unmatched records' do
        effort_same_event = create(:effort, bib_number: 101, event: event)
        effort_different_event = create(:effort, bib_number: 101)
        expect(Effort.count).to eq(2)
        expected_first_names = %w(Bjorn Charlie Lucy)
        expect(expected_first_names).not_to include(effort_same_event.first_name)
        importer = RowImporter.new(importer_params)
        importer.import
        effort_different_event.reload
        expect(effort_different_event.changed?).to be_falsey
        expect(event.efforts.count).to eq(3)
        expect(event.efforts.pluck(:first_name).sort).to eq(expected_first_names)
      end
    end

    context 'when provided with a unique key where at least one field has no data' do
      let(:importer_params) { {rows: valid_rows, model: :efforts, global_attributes: global_attributes,
                               unique_key: [:event_id, :bib_number]} }

      it 'does not match records but instead creates new records' do
        effort_same_event = create(:effort, bib_number: nil, event: event)
        expect(event.efforts.count).to eq(1)
        expected_first_names = %w(Bjorn Charlie Joe Lucy)
        importer = RowImporter.new(importer_params)
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
      importer = RowImporter.new(rows: valid_rows, model: :efforts, global_attributes: global_attributes)
      importer.import
      saved = importer.valid_records
      expect(saved.count).to eq(3)
      expect(saved.map(&:first_name)).to eq(%w(Bjorn Charlie Lucy))
    end
  end

  describe '#invalid_records' do
    it 'returns the attributes of the rejected records' do
      importer = RowImporter.new(rows: mixed_rows, model: :efforts, global_attributes: global_attributes)
      importer.import
      expect(importer.invalid_records.count).to eq(2)
    end
  end
end
