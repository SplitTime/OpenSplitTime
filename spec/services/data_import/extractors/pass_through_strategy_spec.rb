RSpec.describe DataImport::Extractors::PassThroughStrategy do
  subject { DataImport::Extractors::PassThroughStrategy.new(raw_data, options) }
  let(:options) { {model: :effort} }

  describe '#extract' do
    let(:raw_data) { [{first_name: 'Bjorn', lastName: 'Borg', gender: 'male'},
                      {first_name: 'Charlie', lastName: 'Brown', gender: 'male'},
                      {first_name: 'Lucy', lastName: 'Pendergrast', gender: 'female'}] }

    it 'returns an array of attribute rows in OpenStruct format with identical keys' do
      attribute_rows = subject.extract
      expect(attribute_rows.size).to eq(3)
      expect(attribute_rows).to all be_a(OpenStruct)
      expect(attribute_rows.map { |row| row[:first_name] }).to eq(%w(Bjorn Charlie Lucy))
      expect(attribute_rows.map { |row| row[:lastName] }).to eq(%w(Borg Brown Pendergrast))
      expect(attribute_rows.map { |row| row[:gender] }).to eq(%w(male male female))
    end
  end
end
