require 'rails_helper'

describe SortParams do

  describe '.sort_fields' do
    context 'when all parameters are provided' do
      it 'returns an ordered hash of fields' do
        sort = 'name,-age'
        allowed = %w(name age)
        default = {name: :asc}
        expected = {name: :asc, age: :desc}
        validate_sort_fields(sort, allowed, default, expected)
      end

      it 'returns the default if sort does not contain any allowed fields' do
        sort = 'address,zip'
        allowed = %w(name age)
        default = {name: :asc}
        expected = {name: :asc}
        validate_sort_fields(sort, allowed, default, expected)
      end
    end

    context 'when sort is nil or empty' do
      it 'returns the default' do
        sort = nil
        allowed = %w(name age)
        default = {name: :asc}
        expected = {name: :asc}
        validate_sort_fields(sort, allowed, default, expected)
      end
    end

    def validate_sort_fields(sort, allowed, default, expected)
      expect(SortParams.sort_fields(sort, allowed, default)).to eq(expected)
    end
  end

  describe '.sql_string' do
    context 'when sort_fields hash is provided' do
      it 'returns a string of fields in SQL format' do
        sort_fields = {name: :asc, age: :desc}
        expected = 'name asc, age desc'
        validate_sql_string(sort_fields, expected)
      end
    end

    context 'when sort is nil' do
      it 'returns an empty string' do
        sort_fields = nil
        expected = ''
        validate_sql_string(sort_fields, expected)
      end
    end

    context 'when sort is an empty hash' do
      it 'returns an empty string' do
        sort_fields = {}
        expected = ''
        validate_sql_string(sort_fields, expected)
      end
    end

    def validate_sql_string(sort_fields, expected)
      expect(SortParams.sql_string(sort_fields)).to eq(expected)
    end
  end
end
