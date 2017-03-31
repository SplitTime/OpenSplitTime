require 'rails_helper'

describe IncludeParams do
  describe '.prepare' do
    let(:include) { params[:include] }

    context 'when provided with camelCased models and relations in jsonapi format' do
      let(:params) { ActionController::Parameters.new({include: 'course,split.splitTimes'}) }

      it 'returns a string with camelCase converted to underscore' do
        expected = 'course,split.split_times'
        validate_prepare(include, expected)
      end
    end

    context 'when provided with an empty string' do
      let(:params) { ActionController::Parameters.new({include: ''}) }

      it 'returns an empty string' do
        expected = ''
        validate_prepare(include, expected)
      end
    end

    context 'when include param is nil' do
      let(:params) { ActionController::Parameters.new({}) }

      it 'returns an empty string' do
        expected = ''
        validate_prepare(include, expected)
      end
    end

    def validate_prepare(include, expected)
      expect(IncludeParams.prepare(include)).to eq(expected)
    end
  end
end
