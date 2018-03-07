RSpec.shared_examples_for 'locatable' do
  describe '#distance_from' do
    subject { described_class.new(latitude: 40, longitude: -105) }

    context 'when subject and other have latitude and longitude' do
      let(:other) { described_class.new(latitude: 40.1, longitude: -105.1) }

      it 'returns distance from other in meters' do
        expected = 14003.34
        expect(subject.distance_from(other)).to be_within(0.01).of(expected)
      end
    end

    context 'when subject or other does not have latitude or longitude' do
      let(:other) { described_class.new(latitude: nil, longitude: nil) }

      it 'returns nil' do
        expect(subject.distance_from(other)).to be_nil
      end
    end
  end

  describe '#different_location?' do
    subject { described_class.new(latitude: 40, longitude: -105) }

    context 'when subject and other have latitude and longitude and distance is above the threshold' do
      let(:other) { described_class.new(latitude: 40.1, longitude: -105.1) }

      it 'returns true' do
        expect(subject.different_location?(other)).to eq(true)
      end
    end

    context 'when subject and other have latitude and longitude and distance is below the threshold' do
      let(:other) { described_class.new(latitude: 40.0001, longitude: -105.0001) }

      it 'returns false' do
        expect(subject.different_location?(other)).to eq(false)
      end
    end

    context 'when other has no latitude or longitude' do
      let(:other) { described_class.new(latitude: nil, longitude: nil) }

      it 'returns nil' do
        expect(subject.different_location?(other)).to eq(nil)
      end
    end
  end

  describe '#same_location?' do
    subject { described_class.new(latitude: 40, longitude: -105) }

    context 'when subject and other have latitude and longitude and distance is above the threshold' do
      let(:other) { described_class.new(latitude: 40.1, longitude: -105.1) }

      it 'returns false' do
        expect(subject.same_location?(other)).to eq(false)
      end
    end

    context 'when subject and other have latitude and longitude and distance is below the threshold' do
      let(:other) { described_class.new(latitude: 40.0001, longitude: -105.0001) }

      it 'returns true' do
        expect(subject.same_location?(other)).to eq(true)
      end
    end

    context 'when other has no latitude or longitude' do
      let(:other) { described_class.new(latitude: nil, longitude: nil) }

      it 'returns nil' do
        expect(subject.same_location?(other)).to eq(nil)
      end
    end
  end
end
