require 'rails_helper'

RSpec.describe DataImport::Csv::ParseStrategy do
  let(:raw_data) { [{first_name: "Bjorn", last_name: "Borg", gender: "male"},
                    {first_name: "Charlie", last_name: "Brown", gender: "male"},
                    {first_name: "Lucy", last_name: "Pendergrast", gender: "female"}] }
  let(:options) { {model: :effort} }
  subject { DataImport::Csv::ParseStrategy.new(raw_data, options) }

  describe '#read_file' do
    it 'returns an array of attribute rows in OpenStruct format' do
      attribute_rows = subject.parse
      expect(attribute_rows.size).to eq(3)
      expect(attribute_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
      expect(attribute_rows.first[:first_name]).to eq('Bjorn')
    end
  end
end
