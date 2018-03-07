RSpec.shared_examples_for 'data_status_methods' do
  let(:model) { described_class }
  let(:model_name) { model.to_s.underscore.to_sym }
  let(:resource_good) { create(model_name, data_status: :good) }
  let(:resource_bad) { create(model_name, data_status: :bad) }
  let(:resource_questionable) { create(model_name, data_status: :questionable) }

  describe '.valid_status' do
    it 'returns good resources and does not return bad or questionable resources' do
      if model_name == :effort # Generic SplitTime factory does not create split_times that pass validations
        good = resource_good
        bad = resource_bad
        questionable = resource_questionable
        expect(model.all.size).to eq(3)
        expect(model.valid_status.size).to eq(1)
        expect(model.valid_status.include?(good)).to eq(true)
        expect(model.valid_status.include?(bad)).to eq(false)
        expect(model.valid_status.include?(questionable)).to eq(false)
      end
    end
  end

  describe '.invalid_status' do
    it 'returns bad and questionable resources and does not return good resources' do
      if model_name == :effort # Generic SplitTime factory does not create split_times that pass validations
        good = resource_good
        bad = resource_bad
        questionable = resource_questionable
        expect(model.all.size).to eq(3)
        expect(model.invalid_status.size).to eq(2)
        expect(model.invalid_status.include?(good)).to eq(false)
        expect(model.invalid_status.include?(bad)).to eq(true)
        expect(model.invalid_status.include?(questionable)).to eq(true)
      end
    end
  end

  describe '#valid_status?' do
    it 'returns true for a resource that has a good data status' do
      resource = model.new(data_status: :good)
      expect(resource.valid_status?).to eq(true)
    end

    it 'returns false for a resource that has a bad or questionable data status' do
      resource1 = model.new(data_status: :bad)
      resource2 = model.new(data_status: :questionable)
      expect(resource1.valid_status?).to eq(false)
      expect(resource2.valid_status?).to eq(false)
    end
  end

  describe '#invalid_status?' do
    it 'returns false for a resource that has a good data status' do
      resource = model.new(data_status: :good)
      expect(resource.invalid_status?).to eq(false)
    end

    it 'returns true for a resource that has a bad or questionable data status' do
      resource1 = model.new(data_status: :bad)
      resource2 = model.new(data_status: :questionable)
      expect(resource1.invalid_status?).to eq(true)
      expect(resource2.invalid_status?).to eq(true)
    end
  end
end
