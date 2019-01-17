# frozen_string_literal: true

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
    context 'when the "inclusive" parameter is set to false' do
      subject { array.elements_before(element, inclusive: false) }

      context 'when the element is included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'ferret' }

        it 'returns all elements in the array indexed prior to the provided parameter' do
          expect(subject).to eq(%w(cat bird sheep))
        end
      end

      context 'when nil is provided and the array includes a nil element' do
        let(:array) { [1, 2, 3, nil, 5] }
        let(:element) { nil }

        it 'returns the elements prior to nil' do
          expect(subject).to eq([1, 2, 3])
        end
      end

      context 'when the element appears more than once' do
        let(:array) { %w(cat bird sheep ferret sheep coyote) }
        let(:element) { 'sheep' }

        it 'bases the result on the first match of the provided parameter' do
          expect(subject).to eq(%w(cat bird))
        end
      end

      context 'when the first element is provided' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'cat' }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end

      context 'when the provided parameter is not included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'buffalo' }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end
    end

    context 'when the "inclusive" parameter is set to true' do
      subject { array.elements_before(element, inclusive: true) }

      context 'when the element is included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'ferret' }

        it 'returns all elements in the array indexed prior to the provided parameter' do
          expect(subject).to eq(%w(cat bird sheep ferret))
        end
      end

      context 'when nil is provided and the array includes a nil element' do
        let(:array) { [1, 2, 3, nil, 5] }
        let(:element) { nil }

        it 'returns the elements prior to nil' do
          expect(subject).to eq([1, 2, 3, nil])
        end
      end

      context 'when the element appears more than once' do
        let(:array) { %w(cat bird sheep ferret sheep coyote) }
        let(:element) { 'sheep' }

        it 'bases the result on the first match of the provided parameter' do
          expect(subject).to eq(%w(cat bird sheep))
        end
      end

      context 'when the first element is provided' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'cat' }

        it 'returns the first element' do
          expect(subject).to eq(['cat'])
        end
      end

      context 'when the provided parameter is not included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'buffalo' }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end
    end

    context 'when the "inclusive" parameter is not provided' do
      subject { array.elements_before(element) }
      let(:array) { %w(cat bird sheep ferret coyote) }
      let(:element) { 'ferret' }

      it 'functions as thought the "inclusive" parameter were set to false' do
        expect(subject).to eq(%w(cat bird sheep))
      end
    end
  end

  describe '#elements_after' do
    context 'when the "inclusive" parameter is set to false' do
      subject { array.elements_after(element, inclusive: false) }

      context 'when the element is included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'ferret' }

        it 'returns all elements in the array indexed after the provided parameter' do
          expect(subject).to eq(%w(coyote))
        end
      end

      context 'when nil is provided and the array includes a nil element' do
        let(:array) { [1, 2, 3, nil, 5] }
        let(:element) { nil }

        it 'returns the elements after nil' do
          expect(subject).to eq([5])
        end
      end

      context 'when the element appears more than once' do
        let(:array) { %w(cat bird sheep ferret sheep coyote) }
        let(:element) { 'sheep' }

        it 'bases the result on the first match of the provided parameter' do
          expect(subject).to eq(%w(ferret sheep coyote))
        end
      end

      context 'when the last element is provided' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'coyote' }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end

      context 'when the provided parameter is not included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'buffalo' }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end
    end

    context 'when the "inclusive" parameter is set to true' do
      subject { array.elements_after(element, inclusive: true) }

      context 'when the element is included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'ferret' }

        it 'returns the element and all elements in the array indexed after the provided parameter' do
          expect(subject).to eq(%w(ferret coyote))
        end
      end

      context 'when nil is provided and the array includes a nil element' do
        let(:array) { [1, 2, 3, nil, 5] }
        let(:element) { nil }

        it 'returns nil and all elements after nil' do
          expect(subject).to eq([nil, 5])
        end
      end

      context 'when the element appears more than once' do
        let(:array) { %w(cat bird sheep ferret sheep coyote) }
        let(:element) { 'sheep' }

        it 'bases the result on the first match of the provided parameter' do
          expect(subject).to eq(%w(sheep ferret sheep coyote))
        end
      end

      context 'when the last element is provided' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'coyote' }

        it 'returns the last element' do
          expect(subject).to eq(['coyote'])
        end
      end

      context 'when the provided parameter is not included in the array' do
        let(:array) { %w(cat bird sheep ferret coyote) }
        let(:element) { 'buffalo' }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end
    end

    context 'when the "inclusive" parameter is not provided' do
      subject { array.elements_after(element) }
      let(:array) { %w(cat bird sheep ferret coyote) }
      let(:element) { 'ferret' }

      it 'functions as thought the "inclusive" parameter were set to false' do
        expect(subject).to eq(%w(coyote))
      end
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
