RSpec.describe ImportFile do
  describe 'initialization' do
    let(:file) { 'spec/fixtures/files/baddata2015test.xlsx' }
    let(:importer) { ImportFile.new(file) }

    it 'should set up the headers correctly' do
      expect(importer.header1.size).to eq(16)
      expect(importer.header2.size).to eq(16)
      expect(importer.header1[0]).to eq('first_name')
      expect(importer.header1[8]).to eq('Start')
      expect(importer.header1[14]).to eq('Tunnel Out')
      expect(importer.header2[9]).to eq(10)
      expect(importer.header2[12]).to eq(100)
      expect(importer.header2[15]).to eq(140)
    end
  end
end
