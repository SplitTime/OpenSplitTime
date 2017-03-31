require 'rails_helper'

describe FieldParams do
  describe '.prepare' do
    let(:fields) { params[:fields] }

    context 'when provided with fields for a single model in jsonapi format' do
      let(:params) { ActionController::Parameters.new(fields: {'courses' => 'name,description'}) }

      it 'returns a hash with the model name as the key and an array of fields as the value' do
        expected = {'courses' => [:name, :description]}
        validate_prepare(fields, expected)
      end
    end

    context 'when provided with fields for multiple models in jsonapi format' do
      let(:params) { ActionController::Parameters.new(fields: {'courses' => 'name,description',
                                                               'splits' => 'latitude,longitude'}) }

      it 'returns a hash with the model names as the keys and arrays of fields as the values' do
        expected = {'courses' => [:name, :description], 'splits' => [:latitude, :longitude]}
        validate_prepare(fields, expected)
      end
    end

    context 'when provided with a single model and empty string in jsonapi format' do
      let(:params) { ActionController::Parameters.new(fields: {'courses' => ''}) }

      it 'returns a hash with the model name as the key and an empty array as the value' do
        expected = {'courses' => []}
        validate_prepare(fields, expected)
      end
    end

    context 'when provided with an empty hash' do
      let(:params) { ActionController::Parameters.new(fields: {}) }

      it 'returns an empty hash' do
        expected = {}
        validate_prepare(fields, expected)
      end
    end

    context 'when fields param is nil' do
      let(:params) { ActionController::Parameters.new({}) }

      it 'returns an empty hash' do
        expected = {}
        validate_prepare(fields, expected)
      end
    end

    def validate_prepare(fields, expected)
      expect(FieldParams.prepare(fields)).to eq(expected)
    end
  end
end
