require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe ImportFile do

  describe 'initialization' do
    let(:file) { 'spec/fixtures/files/baddata2015test.xlsx' }
    let(:importer) { ImportFile.new(file) }

    it 'should set up the headers correctly' do
      expect(importer.header1.size).to eq(15)
      expect(importer.header2.size).to eq(15)
      expect(importer.header1[0]).to eq('first_name')
      expect(importer.header1[7]).to eq('Start')
      expect(importer.header1[13]).to eq('Tunnel Out')
      expect(importer.header2[8]).to eq(6.5)
      expect(importer.header2[11]).to eq(40)
      expect(importer.header2[14]).to eq(51.3)
    end

  end
end
