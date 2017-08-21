require 'rails_helper'

RSpec.describe ProtoRecord, type: :model do
  it_behaves_like 'transformable'

  describe '#attributes' do
    it 'may be set during initialization' do
      pr = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      attributes = pr.attributes
      expect(attributes).to eq(OpenStruct.new({first_name: 'Joe', age: 21, gender: 'male'}))
    end

    it 'responds to symbols or strings as keys indifferently' do
      pr = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      expect(pr[:first_name]).to eq('Joe')
      expect(pr['first_name']).to eq('Joe')
    end

    it 'sets attributes using symbols or strings indifferently' do
      pr = ProtoRecord.new
      pr[:first_name] = 'Joe'
      expect(pr['first_name']).to eq('Joe')
      pr['first_name'] = 'Joe'
      expect(pr[:first_name]).to eq('Joe')
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

  describe '#record_class' do
    it 'returns the class of the record_type' do
      pr = ProtoRecord.new(record_type: :effort)
      expect(pr.record_class).to eq(Effort)
    end

    it 'returns nil when record_type is nil' do
      pr = ProtoRecord.new
      expect(pr.record_class).to be_nil
    end
  end

  describe '#params_class' do
    it 'returns the class of the record_type' do
      pr = ProtoRecord.new(record_type: :effort)
      expect(pr.params_class).to eq(EffortParameters)
    end

    it 'returns nil when record_type is nil' do
      pr = ProtoRecord.new
      expect(pr.params_class).to be_nil
    end
  end
end
