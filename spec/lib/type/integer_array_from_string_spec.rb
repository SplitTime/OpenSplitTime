# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Type::IntegerArrayFromString do
  module TestDummy
    class QueryModel
      include ::ActiveModel::Model
      include ::ActiveModel::Attributes

      attribute :ids, :integer_array_from_string
    end
  end

  describe '#cast' do
    subject { ::TestDummy::QueryModel.new(ids: ids) }
    context 'when given a Postgres-style array' do
      let(:ids) { '{1001,1003,1005}' }
      it 'casts ids as an array' do
        expect(subject.ids).to eq([1001, 1003, 1005])
      end
    end

    context 'when given an empty Postgres-style array' do
      let(:ids) { '{}' }
      it 'casts as an empty array' do
        expect(subject.ids).to eq([])
      end
    end

    context 'when given an empty string' do
      let(:ids) { '' }
      it 'casts as an empty array' do
        expect(subject.ids).to eq([])
      end
    end

    context 'when given an array' do
      let(:ids) { [1, 2, 3] }
      it 'returns the array' do
        expect(subject.ids).to eq([1, 2, 3])
      end
    end

    context 'when given nil' do
      let(:ids) { nil }
      it 'casts as an empty array' do
        expect(subject.ids).to eq([])
      end
    end
  end
end
