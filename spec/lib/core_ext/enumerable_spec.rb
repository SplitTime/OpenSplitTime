RSpec.describe Enumerable do
  describe '#each_with_iteration' do
    context 'when called without a block' do
      it 'returns an Enumerator' do
        object = [1, 2, 3]
        enum = object.each_with_iteration
        expect(enum).to be_a(Enumerator)
      end

      it 'returns an array containing [next_object, iteration] when #next is called on it' do
        object = %w(dog duck sheep rabbit)
        enum = object.each_with_iteration
        expect(enum.next).to eq(['dog', 1])
        expect(enum.next).to eq(['duck', 1])
        expect(enum.next).to eq(['sheep', 1])
        expect(enum.next).to eq(['rabbit', 1])
        expect(enum.next).to eq(['dog', 2])
        expect(enum.next).to eq(['duck', 2])
      end

      it 'returns an array of [first_object, 1] when #first is called on it' do
        object = %w(dog duck sheep rabbit)
        enum = object.each_with_iteration
        expect(enum.first).to eq(['dog', 1])
      end

      it 'returns an array of n arrays containing [object, iteration] when #first(n) is called on it' do
        object = %w(dog duck sheep rabbit)
        enum = object.each_with_iteration
        n = 6
        expect(enum.first(n).size).to eq(n)
        expect(enum.first(6)).to eq([['dog', 1],
                                     ['duck', 1],
                                     ['sheep', 1],
                                     ['rabbit', 1],
                                     ['dog', 2],
                                     ['duck', 2]])
      end

      it 'responds identically to #each when called on an empty array' do
        object = []
        enum = object.each_with_iteration
        expect { enum.next }.to raise_error StopIteration
        expect(enum.first).to be_nil
        expect(enum.first(5)).to eq([])
      end
    end

    context 'when called with a block' do
      it 'returns an Enumerator' do
        object = [1, 2, 3]
        enum = object.each_with_iteration { |e, i| "Element #{e} at iteration #{i}" }
        expect(enum).to be_a(Enumerator)
      end

      it 'evaluates the next object and iteration using the block when #next is called on it' do
        object = %w(dog duck sheep rabbit)
        enum = object.each_with_iteration { |e, i| "Element #{e} at iteration #{i}" }
        expect(enum.next).to eq("Element dog at iteration 1")
        expect(enum.next).to eq("Element duck at iteration 1")
        expect(enum.next).to eq("Element sheep at iteration 1")
        expect(enum.next).to eq("Element rabbit at iteration 1")
        expect(enum.next).to eq("Element dog at iteration 2")
        expect(enum.next).to eq("Element duck at iteration 2")
      end

      it 'evaluates the first object and iteration using the block when #first is called on it' do
        object = %w(dog duck sheep rabbit)
        enum = object.each_with_iteration { |e, i| "Element #{e} at iteration #{i}" }
        expect(enum.first).to eq("Element dog at iteration 1")
      end

      it 'returns an array of n elements containing evaluations of the block when #first(n) is called on it' do
        object = %w(dog duck sheep rabbit)
        enum = object.each_with_iteration { |e, i| "Element #{e} at iteration #{i}" }
        n = 6
        expect(enum.first(n).size).to eq(n)
        expect(enum.first(6)).to eq(["Element dog at iteration 1",
                                     "Element duck at iteration 1",
                                     "Element sheep at iteration 1",
                                     "Element rabbit at iteration 1",
                                     "Element dog at iteration 2",
                                     "Element duck at iteration 2"])
      end

      it 'responds identically to #each when called on an empty array' do
        object = []
        enum = object.each_with_iteration { |e, i| "Element #{e} at iteration #{i}" }
        expect { enum.next }.to raise_error StopIteration
        expect(enum.first).to be_nil
        expect(enum.first(5)).to eq([])
      end
    end
  end

  describe '#group_by_equality' do
    it 'groups elements of an Array based on equality (rather than hash) of the block evaluation' do
      array = [1, 1.0, 2]
      # Whereas array.group_by { |e| e } would result in {1=>[1], 1.0=>[1.0], 2=>[2]}
      expect(array.group_by_equality { |e| e }).to eq({1=>[1, 1.0], 2=>[2]})
    end

    it 'functions as group_by when block evaluation is identical' do
      array = [1, 1.0, 2]
      expect(array.group_by_equality(&:integer?)).to eq({true => [1, 2], false => [1.0]})
    end
  end
end
