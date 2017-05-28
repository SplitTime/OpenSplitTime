require 'rails_helper'

RSpec.describe ProtoRecord, type: :model do

  describe '#attributes' do
    it 'may be set during initialization' do
      pr = ProtoRecord.new(attributes: {first_name: 'Joe', age: 21, gender: 'male'})
      attributes = pr.attributes
      expect(attributes).to eq(OpenStruct.new({first_name: 'Joe', age: 21, gender: 'male'}))
    end

    it 'receives and responds to missing methods' do
      pr = ProtoRecord.new(attributes: {first_name: 'Joe', age: 21, gender: 'male'})
      expect(pr.first_name).to eq('Joe')
    end

    it 'responds with nil if the attribute is not set' do
      pr = ProtoRecord.new(attributes: {first_name: 'Joe', age: 21, gender: 'male'})
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
      child = ProtoRecord.new(attributes: {first_name: 'Joe', age: 21, gender: 'male'})
      pr = ProtoRecord.new(children: child)
      expect(pr.children).to eq([child])
    end

    it 'can be set at initialization with an array of child records' do
      child1 = ProtoRecord.new(attributes: {first_name: 'Joe'})
      child2 = ProtoRecord.new(attributes: {first_name: 'Jill'})
      pr = ProtoRecord.new(children: [child1, child2])
      expect(pr.children).to eq([child1, child2])
    end

    it 'can be added to using the << operator' do
      child = ProtoRecord.new(attributes: {first_name: 'Joe', age: 21, gender: 'male'})
      pr = ProtoRecord.new
      pr.children << child
      expect(pr.children).to eq([child])
    end
  end
end
