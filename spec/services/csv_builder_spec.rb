# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvBuilder do
  subject { CsvBuilder.new(model_class, resources) }
  let(:model_class) { Split }
  let(:resources) { courses(:hardrock_ccw).ordered_splits.first(2) }
  before { FactoryBot.reload }

  describe '#initialize' do
    it 'initializes given a model_class and resources' do
      expect { subject }.not_to raise_error
    end
  end

  describe '#full_string' do
    context 'when provided with resources whose model has csv attributes defined' do
      let(:splits) { courses(:hardrock_ccw).ordered_splits.first(2) }

      it 'returns a full string with headers in csv format' do
        expected = "Base name,Distance,Kind,Vert gain,Vert loss,Latitude,Longitude,Elevation,Sub split kinds\nStart,0.0,start,0,0,37.811954,-107.664814,2837.84594726562,In\nCunningham,9.3,intermediate,3840,2770,,,,In Out\n"
        expect(subject.full_string).to eq(expected)
      end
    end

    context 'when provided with resources whose model has no csv attributes defined' do
      before do
        allow(subject).to receive(:params_class).and_return(BaseParameters)
      end

      it 'returns a message indicating there are no csv attributes for the provided resource class' do
        expect(subject.full_string).to eq('No csv attributes defined for Split')
      end
    end

    context 'when model_class is nil' do
      let(:model_class) { nil }

      it 'returns a message indicating the model class was not provided' do
        expect(subject.full_string).to eq('No model class was provided')
      end
    end

    context 'when resources is an empty array' do
      let(:resources) { [] }

      it 'returns headers only' do
        expect(subject.full_string).to eq("Base name,Distance,Kind,Vert gain,Vert loss,Latitude,Longitude,Elevation,Sub split kinds\n")
      end
    end

    context 'when resources is nil' do
      let(:resources) { nil }

      it 'returns headers only' do
        expect(subject.full_string).to eq("Base name,Distance,Kind,Vert gain,Vert loss,Latitude,Longitude,Elevation,Sub split kinds\n")
      end
    end
  end

  describe '#model_class_name' do
    context 'when model_class is provided' do
      it 'returns a downcased and pluralized version of the provided model_name' do
        expect(subject.model_class_name).to eq('splits')
      end
    end

    context 'when model_class is not provided' do
      let(:model_class) { nil }

      it 'returns nil' do
        expect(subject.model_class_name).to be_nil
      end
    end
  end
end
