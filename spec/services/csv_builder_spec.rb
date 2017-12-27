require 'rails_helper'

RSpec.describe CsvBuilder do
  let(:splits) { build_stubbed_list(:splits_hardrock_ccw, 2) }
  before { FactoryGirl.reload }

  describe '#initialize' do
    subject { CsvBuilder.new(splits) }

    it 'initializes given resources' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when provided with resources whose model has csv attributes defined' do
    subject { CsvBuilder.new(splits) }

    describe '#full_string' do
      let(:splits) { build_stubbed_list(:splits_hardrock_ccw, 2) }

      it 'returns a full string with headers in csv format' do
        expected = "Base name,Distance,Kind,Vert gain,Vert loss,Latitude,Longitude,Elevation,Sub split kinds\nStart,0.0,start,0,0,,,,In\nCunningham,9.3,intermediate,3840,2770,,,,In Out\n"
        expect(subject.full_string).to eq(expected)
      end
    end

    describe '#model_class_name' do
      it 'returns the name of the model belonging to the provided resources' do
        expect(subject.model_class_name).to eq('splits')
      end
    end
  end

  context 'when provided with resources whose model has no csv attributes defined' do
    subject { CsvBuilder.new(splits) }
    before do
      allow(subject).to receive(:params_class).and_return(BaseParameters)
    end

    describe '#full_string' do
      it 'returns a message indicating there are no csv attributes for the provided resource class' do
        expect(subject.full_string).to eq('No csv attributes defined for Split')
      end
    end

    describe '#model_class_name' do
      it 'returns the name of the model belonging to the provided resources' do
        expect(subject.model_class_name).to eq('splits')
      end
    end
  end

  context 'when provided with an empty array' do
    subject { CsvBuilder.new([]) }

    describe '#full_string' do
      it 'returns a message indicating there are no records' do
        expect(subject.full_string).to eq('No resources were provided for export')
      end
    end

    describe '#model_class_name' do
      it 'returns "unknown_class"' do
        expect(subject.model_class_name).to eq('unknown_class')
      end
    end
  end

  context 'when provided with nil' do
    subject { CsvBuilder.new(nil) }

    describe '#full_string' do
      it 'returns a message indicating there are no records' do
        expect(subject.full_string).to eq('No resources were provided for export')
      end
    end

    describe '#model_class_name' do
      it 'returns "unknown_class"' do
        expect(subject.model_class_name).to eq('unknown_class')
      end
    end
  end
end
