require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe CsvBuilder do
  let(:splits) { build_stubbed_list(:splits_hardrock_ccw, 16) }

  describe '#initialize' do
    subject { CsvBuilder.new(splits) }

    it 'initializes given resources' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when provided with resources whose model has csv attributes defined' do
    subject { CsvBuilder.new(splits) }

    describe '#headers' do
      it 'returns an array of humanized headers for the provided model' do
        expect(subject.headers).to eq(['Base name', 'Name extensions', 'Distance from start', 'Vert gain from start',
                                       'Vert loss from start', 'Latitude', 'Longitude', 'Elevation'])
      end
    end

    describe '#export_attributes' do
      it 'returns an array of attributes for the provided model' do
        expect(subject.export_attributes).to eq(%w(base_name name_extensions distance_from_start vert_gain_from_start vert_loss_from_start latitude longitude elevation))
      end
    end

    describe '#resources' do
      it 'returns the provided resources' do
        expect(subject.resources).to eq(splits)
      end
    end
  end

  context 'when provided with resources whose model has no csv attributes defined' do
    subject { CsvBuilder.new(splits) }
    before do
      allow(subject).to receive(:params_class).and_return(BaseParameters)
    end

    describe '#headers' do
      it 'returns an array containing a message indicating there are no csv attributes for the provided resource class' do
        expect(subject.headers).to eq(['No csv attributes defined for Split'])
      end
    end

    describe '#attributes' do
      it 'returns an empty array' do
        expect(subject.export_attributes).to eq([])
      end
    end

    describe '#resources' do
      it 'returns the provided resources' do
        expect(subject.resources).to eq(splits)
      end
    end
  end

  context 'when provided with an empty array' do
    subject { CsvBuilder.new([]) }

    describe '#headers' do
      it 'returns an array containing a message indicating there are no records' do
        expect(subject.headers).to eq(['No resources were provided for export'])
      end
    end

    describe '#attributes' do
      it 'returns an empty array' do
        expect(subject.export_attributes).to eq([])
      end
    end

    describe '#resources' do
      it 'returns an empty array' do
        expect(subject.resources).to eq([])
      end
    end
  end

  context 'when provided with nil' do
    subject { CsvBuilder.new(nil) }

    describe '#headers' do
      it 'returns an array containing a message indicating there are no records' do
        expect(subject.headers).to eq(['No resources were provided for export'])
      end
    end

    describe '#attributes' do
      it 'returns an empty array' do
        expect(subject.export_attributes).to eq([])
      end
    end

    describe '#resources' do
      it 'returns the provided resources' do
        expect(subject.resources).to eq([])
      end
    end
  end
end
