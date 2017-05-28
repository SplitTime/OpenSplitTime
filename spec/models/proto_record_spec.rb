require 'rails_helper'

RSpec.describe ProtoRecord, type: :model do
  it_behaves_like 'transformable'

  describe '#attributes' do
    it 'may be set during initialization' do
      pr = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      attributes = pr.attributes
      expect(attributes).to eq(OpenStruct.new({first_name: 'Joe', age: 21, gender: 'male'}))
    end

    it 'receives and responds to missing methods' do
      pr = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      expect(pr.first_name).to eq('Joe')
    end

    it 'responds with nil if the attribute is not set' do
      pr = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      expect(pr.favorite_color).to eq(nil)
    end

    it 'sets attributes for any method not otherwise defined' do
      pr = ProtoRecord.new
      pr.first_name = 'Joe'
      expect(pr.first_name).to eq('Joe')
    end
  end

  describe '#children' do
    it 'can be set at initialization with a single child record' do
      child = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      pr = ProtoRecord.new(first_name: 'Fred', children: child)
      expect(pr.children).to eq([child])
      expect(pr.attributes).not_to respond_to(:children)
      expect(pr.to_h).to eq({first_name: 'Fred'})
    end

    it 'can be set at initialization with an array of child records' do
      child1 = ProtoRecord.new(first_name: 'Joe')
      child2 = ProtoRecord.new(first_name: 'Jill')
      pr = ProtoRecord.new(age: 99, children: [child1, child2])
      expect(pr.children).to eq([child1, child2])
      expect(pr.attributes).not_to respond_to(:children)
      expect(pr.to_h).to eq({age: 99})
    end

    it 'can be added to using the << operator' do
      child = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      pr = ProtoRecord.new(favorite_color: 'Red')
      pr.children << child
      expect(pr.children).to eq([child])
      expect(pr.attributes).not_to respond_to(:children)
      expect(pr.to_h).to eq({favorite_color: 'Red'})
    end
  end
end
