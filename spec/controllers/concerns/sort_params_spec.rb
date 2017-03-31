require 'rails_helper'

describe SortParams do
  describe '.prepare' do
    let(:sort) { params[:sort] }

    context 'when provided with a sort param in jsonapi format' do
      let(:params) { ActionController::Parameters.new(sort: 'name,-age') }

      it 'returns an ordered hash of fields' do
        expected = {'name' => :asc, 'age' => :desc}
        validate_prepare(sort, expected)
      end
    end

    context 'when sort is nil' do
      let(:params) { ActionController::Parameters.new(sort: nil) }

      it 'returns an empty hash' do
        expected = {}
        validate_prepare(sort, expected)
      end
    end

    context 'when sort is an empty string' do
      let(:params) { ActionController::Parameters.new(sort: '') }

      it 'returns an empty hash' do
        expected = {}
        validate_prepare(sort, expected)
      end
    end

    def validate_prepare(sort, expected)
      expect(SortParams.prepare(sort)).to eq(expected)
    end
  end
end
