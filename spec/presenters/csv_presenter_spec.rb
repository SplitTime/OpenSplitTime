require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe CsvPresenter do
  subject { CsvPresenter.new(model: 'split', resources: splits) }
  let(:splits) { build_stubbed_list(:splits_hardrock_ccw, 16) }

  describe '#initialize' do
    it 'initializes given a model and resources' do
      expect { subject }.not_to raise_error
    end

    it 'raises an error if model argument is not given' do
      expect { CsvPresenter.new(resources: splits) }
          .to raise_error(/must include model/)
    end

    it 'raises an error if resources argument is not given' do
      expect { CsvPresenter.new(model: 'split') }
          .to raise_error(/must include resources/)
    end

    it 'raises an error if any argument other than model and resources is given' do
      expect { CsvPresenter.new(model: 'split', resources: splits, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#headers' do
    it 'returns an array of humanized headers for the provided model' do
      expect(subject.headers).to eq(['Base name', 'Name extensions', 'Distance from start', 'Vert gain from start',
                                     'Vert loss from start', 'Latitude', 'Longitude', 'Elevation'])
    end
  end

  describe '#attributes' do
    it 'returns an array of attributes for the provided model' do
      expect(subject.attributes).to eq(%w(base_name name_extensions distance_from_start vert_gain_from_start vert_loss_from_start latitude longitude elevation))
    end
  end

  describe '#resources' do
    it 'returns the provided resources' do
      expect(subject.resources).to eq(splits)
    end
  end
end
