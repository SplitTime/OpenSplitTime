require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe BaseQuery do
  describe '.sql_order_from_hash' do
    context 'when sort_fields hash is provided' do
      it 'returns a string of fields in SQL format' do
        sort_fields = {name: :asc, age: :desc}
        allowed = %w(name age)
        default = 'name asc'
        expected = 'name asc, age desc'
        validate_sql_order_from_hash(sort_fields, allowed, default, expected)
      end
    end

    context 'when sort is nil' do
      it 'returns the default string' do
        sort_fields = nil
        allowed = %w(name age)
        default = 'name asc'
        expected = 'name asc'
        validate_sql_order_from_hash(sort_fields, allowed, default, expected)
      end
    end

    context 'when sort is an empty hash' do
      it 'returns the default string' do
        sort_fields = {}
        allowed = %w(name age)
        default = 'name asc'
        expected = 'name asc'
        validate_sql_order_from_hash(sort_fields, allowed, default, expected)
      end
    end

    def validate_sql_order_from_hash(sort_fields, allowed, default, expected)
      expect(BaseQuery.sql_order_from_hash(sort_fields, allowed, default)).to eq(expected)
    end
  end
end
