require 'rails_helper'

RSpec.describe EffortImportDataPreparer, type: :model do

  describe 'output_row' do

    it 'should function properly when passed first name, last name, and gender' do
      schema_array = [:first_name, :last_name, :gender]
      input_row = %w(Joe Hardman male)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman male))
    end

    it 'should return data unchanged and in the same order when no prep is needed' do
      schema_array = [:first_name, :last_name, :state_code, :country_code, :gender]
      input_row = %w(Joe Hardman TX US male)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(input_row)
    end

    it 'should return nil when country and state codes are empty strings' do
      schema_array = [:first_name, :last_name, :state_code, :country_code]
      input_row = ['Joe', 'Hardman', '', '']
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(['Joe', 'Hardman', nil, nil])
    end

    it 'should properly prepare state and country data' do
      schema_array = [:first_name, :last_name, :state_code, :country_code]
      input_row = ['Joe', 'Hardman', 'Texas', 'United States']
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman TX US))
    end

    it 'should discover country nicknames' do
      schema_array = [:first_name, :last_name, :country_code]
      input_row = %w(Joe Hardman England)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman GB))
    end

    it 'should discover foreign state-like subregions' do
      schema_array = [:first_name, :last_name, :state_code, :country_code]
      input_row = %w(Joe Hardman Surrey England)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman SRY GB))
      input_row = %w(Joe Hardman Hamburg Germany)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman HH DE))
    end

    it 'should preserve state data when no country is given' do
      schema_array = [:first_name, :last_name, :state_code]
      input_row = %w(Joe Hardman Colorado)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(input_row)
    end

    it 'should preserve state data when country does not have subregions' do
      schema_array = [:first_name, :last_name, :state_code, :country_code]
      input_row = ['Joe', 'Hardman', 'Northside', 'Cayman Islands']
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman Northside KY))
    end

    it 'should preserve state data when subregion does not exist in country' do
      schema_array = [:first_name, :last_name, :state_code, :country_code]
      input_row = ['Joe', 'Hardman', 'London', 'Great Britain']
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman London GB))
    end

    it 'should properly prepare gender data' do
      schema_array = [:first_name, :last_name, :gender]
      input_row = %w(Joe Hardman M)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Joe Hardman male))
      input_row = %w(Jane Flash FEMALE)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(%w(Jane Flash female))
    end

    it 'should properly prepare birthdate data when passed as a string' do
      schema_array = [:first_name, :last_name, :birthdate]
      input_row = %w(John Racer 1967-08-08)
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(['John', 'Racer', Date.new(1967, 8, 8)])
    end

    it 'should properly prepare birthdate data when passed as a date object' do
      schema_array = [:first_name, :last_name, :birthdate]
      input_row = ['John', 'Racer', Date.new(1967, 8, 8)]
      preparer = EffortImportDataPreparer.new(input_row, schema_array)
      expect(preparer.output_row).to eq(['John', 'Racer', Date.new(1967, 8, 8)])
    end

  end

end