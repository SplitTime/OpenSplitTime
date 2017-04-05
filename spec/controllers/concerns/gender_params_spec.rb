require 'rails_helper'

describe GenderParams do
  describe '.prepare' do
    let(:gender) { params[:gender] }

    context 'when provided with params[:gender] = "male"' do
      let(:params) { ActionController::Parameters.new(gender: 'male') }

      it 'returns an array containing [0]' do
        expected = [0]
        validate_prepare(gender, expected)
      end
    end

    context 'when provided with params[:gender] = "female"' do
      let(:params) { ActionController::Parameters.new(gender: 'female') }

      it 'returns an array containing [1]' do
        expected = [1]
        validate_prepare(gender, expected)
      end
    end

    context 'when provided with the names of both genders' do
      let(:params) { ActionController::Parameters.new(gender: 'male,female') }

      it 'returns an array containing numeric values for both genders' do
        expected = [0, 1]
        validate_prepare(gender, expected)
      end
    end

    context 'when provided with params[:gender] = "0"' do
      let(:params) { ActionController::Parameters.new(gender: '0') }

      it 'returns an array containing [0]' do
        expected = [0]
        validate_prepare(gender, expected)
      end
    end

    context 'when provided with params[:gender] = "1"' do
      let(:params) { ActionController::Parameters.new(gender: '1') }

      it 'returns an array containing [1]' do
        expected = [1]
        validate_prepare(gender, expected)
      end
    end

    context 'when provided with numbers representing both genders' do
      let(:params) { ActionController::Parameters.new(gender: '0,1') }

      it 'returns an array containing numeric values for both genders' do
        expected = [0, 1]
        validate_prepare(gender, expected)
      end
    end

    context 'when provided with an empty string' do
      let(:params) { ActionController::Parameters.new(gender: '') }

      it 'returns an array containing numeric values for both genders' do
        expected = [0, 1]
        validate_prepare(gender, expected)
      end
    end

    context 'when gender param is nil' do
      let(:params) { ActionController::Parameters.new({}) }

      it 'returns an array containing numeric values for both genders' do
        expected = [0, 1]
        validate_prepare(gender, expected)
      end
    end

    def validate_prepare(gender, expected)
      expect(GenderParams.prepare(gender)).to eq(expected)
    end
  end
end
