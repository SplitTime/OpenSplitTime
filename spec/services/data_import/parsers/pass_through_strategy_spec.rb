require 'rails_helper'

RSpec.describe DataImport::Parsers::PassThroughStrategy do
  let(:raw_data) { [{first_name: "Bjorn", last_name: "Borg", gender: "male"},
                    {first_name: "Charlie", last_name: "Brown", gender: "male"},
                    {first_name: "Lucy", last_name: "Pendergrast", gender: "female"}] }
  let(:options) { {model: :effort} }
  subject { DataImport::Parsers::PassThroughStrategy.new(raw_data, options) }

  describe '#parse' do
    it 'returns an array of attribute rows in OpenStruct format' do
      attribute_rows = subject.parse
      expect(attribute_rows.size).to eq(3)
      expect(attribute_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
      expect(attribute_rows.map { |row| row[:first_name] }).to eq(%w(Bjorn Charlie Lucy))
    end
  end
end
