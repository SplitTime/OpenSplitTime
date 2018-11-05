# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProtoRecord, type: :model do
  it_behaves_like 'transformable'

  describe '#[]=' do
    it 'may be used to add a key to an existing proto_record' do
      pr = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      pr[:id] = 1
      expect(pr[:id]).to eq(1)
    end
  end

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

  describe '#to_h' do
    it 'returns a hash of the attributes' do
      pr = ProtoRecord.new(first_name: 'Joe', age: 21, gender: 'male')
      hash = pr.to_h
      expect(hash).to eq({first_name: 'Joe', age: 21, gender: 'male'})
    end
  end

  describe '#resource_attributes' do
    it 'returns attributes in the format returned by the record_class' do
      pr = ProtoRecord.new(record_type: :raw_time, bib_number: '101', absolute_time: '2017-10-31 08:00:00-06:00', sub_split_kind: 'in')
      expect(pr.resource_attributes).to eq(bib_number: '101', absolute_time: '2017-10-31 14:00:00 +0000', sub_split_kind: 'In')
    end
  end

  describe '#transform_as' do
    let(:pr) { ProtoRecord.new(attributes) }
    before { pr.transform_as(model, options) }

    context 'for an effort' do
      let(:model) { :effort }
      let(:attributes) { {sex: 'M', country: 'United States', state: 'California', birthdate: '09/01/66'} }
      let(:options) { {event: event} }
      let(:event) { Event.new(id: 1, start_time: start_time) }
      let(:start_time) { '2018-06-30 08:00:00' }

      it 'sets the record type and normalizes data' do
        expect(pr.record_type).to eq(:effort)
        expect(pr.to_h).to eq({gender: 'male', country_code: 'US', state_code: 'CA', birthdate: '1966-09-01', event_id: event.id, scheduled_start_time: start_time})
      end
    end

    context 'for a split' do
      let(:model) { :split }
      let(:attributes) { {distance: distance} }
      let(:baseline_split) { Split.new(distance: distance) }
      let(:distance) { 10.5 } # miles
      let(:options) { {event: event} }
      let(:event) { Event.new }

      it 'sets the record type and normalizes data' do
        expect(pr.record_type).to eq(:split)
        expect(pr.to_h[:distance_from_start]).to eq(baseline_split.distance_from_start)
      end
    end
  end
end
