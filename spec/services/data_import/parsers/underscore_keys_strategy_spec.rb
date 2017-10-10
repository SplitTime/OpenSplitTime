RSpec.describe DataImport::Parsers::UnderscoreKeysStrategy do
  let(:options) { {model: :effort} }
  subject { DataImport::Parsers::UnderscoreKeysStrategy.new(raw_data, options) }

  describe '#parse' do
    context 'when all headers are in underscore format' do
      let(:raw_data) { [{first_name: 'Bjorn', last_name: 'Borg', gender: 'male'},
                        {first_name: 'Charlie', last_name: 'Brown', gender: 'male'},
                        {first_name: 'Lucy', last_name: 'Pendergrast', gender: 'female'}] }

      it 'returns an array of attribute rows in OpenStruct format with identical keys' do
        attribute_rows = subject.parse
        expect(attribute_rows.size).to eq(3)
        expect(attribute_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
        expect(attribute_rows.map { |row| row[:first_name] }).to eq(%w(Bjorn Charlie Lucy))
        expect(attribute_rows.map { |row| row[:last_name] }).to eq(%w(Borg Brown Pendergrast))
        expect(attribute_rows.map { |row| row[:gender] }).to eq(%w(male male female))
      end
    end

    context 'when headers are in other than underscore format' do
      let(:raw_data) { [{firstName: 'Bjorn', lastName: 'Borg', gender: 'male'},
                        {FIRST_NAME: 'Charlie', LAST_NAME: 'Brown', GENDER: 'male'},
                        {first_name: 'Lucy', last_name: 'Pendergrast', gender: 'female'}] }

      it 'returns an array of attribute rows in OpenStruct format with underscored keys' do
        attribute_rows = subject.parse
        expect(attribute_rows.size).to eq(3)
        expect(attribute_rows.all? { |row| row.is_a?(OpenStruct) }).to eq(true)
        expect(attribute_rows.map { |row| row[:first_name] }).to eq(%w(Bjorn Charlie Lucy))
        expect(attribute_rows.map { |row| row[:last_name] }).to eq(%w(Borg Brown Pendergrast))
        expect(attribute_rows.map { |row| row[:gender] }).to eq(%w(male male female))
      end
    end
  end
end
