require 'rails_helper'

describe Array do
  describe '#elements_before' do
    it 'returns all elements in the array indexed prior to the provided parameter' do
      array = %w(cat bird sheep ferret coyote)
      sub = array.elements_before('ferret')
      expect(sub).to eq(%w(cat bird sheep))
    end

    it 'returns the elements prior to nil when nil is provided' do
      array = [1, 2, 3, nil, 5]
      sub = array.elements_before(nil)
      expect(sub).to eq([1, 2, 3])
    end

    it 'bases the result on the first match of the provided parameter' do
      array = %w(cat bird sheep ferret sheep coyote)
      sub = array.elements_before('sheep')
      expect(sub).to eq(%w(cat bird))
    end

    it 'returns an empty array when the first element is provided' do
      array = %w(cat bird sheep ferret coyote)
      sub = array.elements_before('cat')
      expect(sub).to eq([])
    end

    it 'returns an empty array when the provided parameter is not included in the array' do
      array = %w(cat bird sheep ferret coyote)
      sub = array.elements_before('buffalo')
      expect(sub).to eq([])
    end
  end

  describe '#elements_after' do
    it 'returns all elements in the array indexed after to the provided parameter' do
      array = %w(cat bird sheep ferret coyote)
      sub = array.elements_after('ferret')
      expect(sub).to eq(%w(coyote))
    end

    it 'returns the elements after nil when nil is provided' do
      array = [1, 2, 3, nil, 5]
      sub = array.elements_after(nil)
      expect(sub).to eq([5])
    end

    it 'bases the result on the first match of the provided parameter' do
      array = %w(cat bird sheep ferret sheep coyote)
      sub = array.elements_after('sheep')
      expect(sub).to eq(%w(ferret sheep coyote))
    end

    it 'returns an empty array when the last element is provided' do
      array = %w(cat bird sheep ferret coyote)
      sub = array.elements_after('coyote')
      expect(sub).to eq([])
    end

    it 'returns an empty array when the provided parameter is not included in the array' do
      array = %w(cat bird sheep ferret coyote)
      sub = array.elements_after('buffalo')
      expect(sub).to eq([])
    end
  end
end