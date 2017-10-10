RSpec.describe DataImport::Parsers::PassThroughStrategy do
  let(:options) { {model: :effort} }
  subject { DataImport::Parsers::PassThroughStrategy.new(raw_data, options) }

  describe '#parse' do
    let(:raw_data) { [{first_name: 'Bjorn', lastName: 'Borg', gender: 'male'},
                      {first_name: 'Charlie', lastName: 'Brown', gender: 'male'},
                      {first_name: 'Lucy', lastName: 'Pendergrast', gender: 'female'}] }

    it 'returns an array of attribute rows in OpenStruct format with identical keys' do
      attribute_rows = subject.parse
      expect(attribute_rows.size).to eq(3)
      expect(attribute_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
      expect(attribute_rows.map { |row| row[:first_name] }).to eq(%w(Bjorn Charlie Lucy))
      expect(attribute_rows.map { |row| row[:lastName] }).to eq(%w(Borg Brown Pendergrast))
      expect(attribute_rows.map { |row| row[:gender] }).to eq(%w(male male female))
    end
  end
end
