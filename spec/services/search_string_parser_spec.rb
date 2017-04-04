require 'rails_helper'

RSpec.describe SearchStringParser, type: :model do
  describe '#number' do
    it 'returns a string containing a single integer passed in the search_string' do
      search_string = 'John Doe 123'
      parser = SearchStringParser.new(search_string)
      expect(parser.number_component).to eq('123')
    end

    it 'returns a string containing multiple integers passed in the search_string' do
      search_string = 'John 123 Doe 456'
      parser = SearchStringParser.new(search_string)
      expect(parser.number_component).to eq('123 456')
    end
  end

  describe '#state_component' do
    it 'returns a string containing the code of a state of the US matching the Carmen database' do
      search_string = 'John Doe Arizona'
      parser = SearchStringParser.new(search_string)
      expect(parser.state_component).to eq('AZ')
    end

    it 'returns a string containing the code of a province of Canada matching the Carmen database' do
      search_string = 'John Doe Alberta'
      parser = SearchStringParser.new(search_string)
      expect(parser.state_component).to eq('AB')
    end

    it 'functions properly when the state or province name is two words' do
      search_string = 'John Doe British Columbia'
      parser = SearchStringParser.new(search_string)
      expect(parser.state_component).to eq('BC')
    end

    it 'functions properly with multiple states or provinces' do
      search_string = 'John Doe New York Arizona Alberta'
      parser = SearchStringParser.new(search_string)
      expect(parser.state_component).to eq('NY AZ AB')
    end

    it 'detects state codes' do
      search_string = 'John Doe AZ NY'
      parser = SearchStringParser.new(search_string)
      expect(parser.state_component).to eq('AZ NY')
    end
  end

  describe '#country_component' do
    it 'returns a string containing codes of country_component matching the Carmen country database' do
      search_string = 'John Doe Australia'
      parser = SearchStringParser.new(search_string)
      expect(parser.country_component).to eq('AU')
    end

    it 'functions properly when the country name is two words' do
      search_string = 'John Doe United States'
      parser = SearchStringParser.new(search_string)
      expect(parser.country_component).to eq('US')
    end

    it 'functions properly with multiple countries' do
      search_string = 'John Doe United States France'
      parser = SearchStringParser.new(search_string)
      expect(parser.country_component).to eq('US FR')
    end

    it 'detects country codes' do
      search_string = 'John Doe US CA'
      parser = SearchStringParser.new(search_string)
      expect(parser.country_component).to eq('US CA')
    end

    it 'works with a lone country code' do
      search_string = 'de'
      parser = SearchStringParser.new(search_string)
      expect(parser.country_component).to eq('DE')
    end
  end

  describe '#remainder_component' do
    it 'returns a string containing search words that do not fall into the integer, country_component, or state_component category' do
      search_string = '123 John Doe Arizona Alberta New York'
      parser = SearchStringParser.new(search_string)
      expect(parser.remainder_component).to eq('john doe')
    end

    it 'works regardless of the ordering of terms' do
      search_string = 'Washington 123 North Carolina United Kingdom John Doe Arizona Alberta New York'
      parser = SearchStringParser.new(search_string)
      expect(parser.remainder_component).to eq('john doe')
    end

    it 'works regardless of string case' do
      search_string = 'kilian spain'
      parser = SearchStringParser.new(search_string)
      expect(parser.remainder_component).to eq('kilian')
    end

    it 'removes state and country codes' do
      search_string = 'John Doe US NC'
      parser = SearchStringParser.new(search_string)
      expect(parser.remainder_component).to eq('john doe')
    end

    it 'removes state and country codes in the correct order when the term matches both a state and a country' do
      search_string = 'New Mexico'
      parser = SearchStringParser.new(search_string)
      expect(parser.remainder_component).to eq('')
    end
  end
end
