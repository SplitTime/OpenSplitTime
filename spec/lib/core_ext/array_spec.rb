require_relative '../../../lib/core_ext/array'

RSpec.describe Array do
  describe '#average' do
    it 'computes the average of elements in the Array' do
      array = [1, 2, 3]
      expect(array.average).to eq(2)
    end

    it 'works properly when the answer is not an integer' do
      array = [1, 2]
      expect(array.average).to eq(1.5)
    end
  end

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

  describe '#included_before?' do
    it 'returns true if the subject element is included in the array indexed prior to the index element' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'ferret'
      subject_element = 'bird'
      expect(array.included_before?(index_element, subject_element)).to eq(true)
    end

    it 'returns false if the subject element is not included in the array indexed prior to the index element' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'ferret'
      subject_element = 'coyote'
      expect(array.included_before?(index_element, subject_element)).to eq(false)
    end

    it 'returns false if the index element is not found in the array' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'buffalo'
      subject_element = 'bird'
      expect(array.included_before?(index_element, subject_element)).to eq(false)
    end

    it 'returns false if the subject element is not found in the array' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'sheep'
      subject_element = 'buffalo'
      expect(array.included_before?(index_element, subject_element)).to eq(false)
    end

    it 'works as expected when nil is provided as the index element and the subject element appears before' do
      array = [1, 2, 3, nil, 5]
      index_element = nil
      subject_element = 2
      expect(array.included_before?(index_element, subject_element)).to eq(true)
    end

    it 'works as expected when nil is provided as the index element and the subject element does not appear before' do
      array = [1, 2, 3, nil, 5]
      index_element = nil
      subject_element = 5
      expect(array.included_before?(index_element, subject_element)).to eq(false)
    end

    it 'works as expected when nil is provided as the subject element and appears before' do
      array = [1, nil, 3, 4, 5]
      index_element = 4
      subject_element = nil
      expect(array.included_before?(index_element, subject_element)).to eq(true)
    end

    it 'works as expected when nil is provided as the subject element and does not appear before' do
      array = [1, 2, 3, 4, 5]
      index_element = 4
      subject_element = nil
      expect(array.included_before?(index_element, subject_element)).to eq(false)
    end
  end

  describe '#included_after?' do
    it 'returns true if the subject element is included in the array indexed after the index element' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'bird'
      subject_element = 'ferret'
      expect(array.included_after?(index_element, subject_element)).to eq(true)
    end

    it 'returns false if the subject element is not included in the array indexed after the index element' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'bird'
      subject_element = 'cat'
      expect(array.included_after?(index_element, subject_element)).to eq(false)
    end

    it 'returns false if the index element is not found in the array' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'buffalo'
      subject_element = 'bird'
      expect(array.included_after?(index_element, subject_element)).to eq(false)
    end

    it 'returns false if the subject element is not found in the array' do
      array = %w(cat bird sheep ferret coyote)
      index_element = 'sheep'
      subject_element = 'buffalo'
      expect(array.included_after?(index_element, subject_element)).to eq(false)
    end

    it 'works as expected when nil is provided as the index element and the subject element appears after' do
      array = [1, nil, 3, 4, 5]
      index_element = nil
      subject_element = 4
      expect(array.included_after?(index_element, subject_element)).to eq(true)
    end

    it 'works as expected when nil is provided as the index element and the subject element does not appear after' do
      array = [1, 2, 3, nil, 5]
      index_element = nil
      subject_element = 2
      expect(array.included_after?(index_element, subject_element)).to eq(false)
    end

    it 'works as expected when nil is provided as the subject element and appears after' do
      array = [1, 2, 3, nil, 5]
      index_element = 2
      subject_element = nil
      expect(array.included_after?(index_element, subject_element)).to eq(true)
    end

    it 'works as expected when nil is provided as the subject element and does not appear after' do
      array = [1, 2, 3, 4, 5]
      index_element = 4
      subject_element = nil
      expect(array.included_after?(index_element, subject_element)).to eq(false)
    end
  end
end
