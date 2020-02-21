RSpec.shared_examples "initializes with model and resources" do
  let(:resources) { build_stubbed_list(:user, 3) }

  context 'when provided with a model and resources' do
    it 'initializes without error' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when no model argument is given' do
    let(:model) { nil }

    it 'raises an error' do
      expect { subject }.to raise_error(/model must be provided/)
    end
  end

  context 'when no resources argument is given' do
    let(:resources) { nil }

    it 'raises an error' do
      expect { subject }.to raise_error(/resources must be provided/)
    end
  end

  context 'when any resource is not a member of the model class' do
    let(:resources) { [Effort.new] }

    it 'raises an error' do
      expect(resources.first.class).not_to eq(model)
      expect { subject }.to raise_error(/all resources must be members of the model class/)
    end
  end
end
