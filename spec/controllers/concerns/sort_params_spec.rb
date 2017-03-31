require 'rails_helper'

describe SortParams do
  describe '.prepare' do
    it 'returns an ordered hash of fields' do
      sort = 'name,-age'
      expected = {name: :asc, age: :desc}
      validate_prepare(sort, expected)
    end

    it 'when sort is nil, returns an empty hash' do
      sort = nil
      expected = {}
      validate_prepare(sort, expected)
    end

    it 'when sort is an empty string, returns an empty hash' do
      sort = ''
      expected = {}
      validate_prepare(sort, expected)
    end

    def validate_prepare(sort, expected)
      expect(SortParams.prepare(sort)).to eq(expected)
    end
  end
end
