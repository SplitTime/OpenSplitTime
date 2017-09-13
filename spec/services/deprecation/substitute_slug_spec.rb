require 'rails_helper'

RSpec.describe Deprecation::SubstituteSlug do
  describe '.perform' do
    subject { Deprecation::SubstituteSlug.perform(model, slug) }

    context 'when given a model and slug that exists in the hash' do
      let(:model) { :events }
      let(:slug) { '2017-rattlesnake-ramble-kids-race' }

      it 'returns the substituted slug' do
        expect(subject).to eq('2017-rattlesnake-ramble-kids-run')
      end
    end

    context 'when given a slug that does not exist in the hash' do
      let(:model) { :events }
      let(:slug) { 'not-deprecated-slug' }

      it 'returns the given slug' do
        expect(subject).to eq(slug)
      end
    end

    context 'when given a model that does not exist in the hash' do
      let(:model) { :new_model }
      let(:slug) { 'new-slug' }

      it 'raises an error' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end
end
