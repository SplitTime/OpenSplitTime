require 'rails_helper'

include ActionDispatch::TestProcess

RSpec.describe DataImport::Csv::ReadStrategy do
  let(:file_path) { "#{Rails.root}/spec/fixtures/files/test_efforts.csv" }
  subject { DataImport::Csv::ReadStrategy.new(file_path) }

  describe '#read_file' do
    it 'returns raw data in hash format' do
      raw_data = subject.read_file
      expect(raw_data.size).to eq(3)
      expect(raw_data.all? { |row| row.is_a?(Hash) }).to eq(true)
    end
  end
end
