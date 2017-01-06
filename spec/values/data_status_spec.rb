require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe DataStatus do
  describe '.worst' do
    it 'returns :bad when the array includes any :bad element' do
      data_status_array = [:good, :questionable, nil, :bad, :good]
      expect(DataStatus.worst(data_status_array)).to eq('bad')
    end

    it 'returns :questionable when the array includes any :questionable element but no :bad element' do
      data_status_array = [:good, :questionable, nil, :good, :good]
      expect(DataStatus.worst(data_status_array)).to eq('questionable')
    end

    it 'returns nil when the array includes any nil element but no :bad or :questionable elements' do
      data_status_array = [:good, :good, nil, :good, :good]
      expect(DataStatus.worst(data_status_array)).to be_nil
    end

    it 'returns :good when the array includes no :bad, :questionable, or nil elements' do
      data_status_array = [:good, :good, :good, :good, :good]
      expect(DataStatus.worst(data_status_array)).to eq('good')
    end

    it 'returns :good when the array includes only :good and :confirmed elements' do
      data_status_array = [:good, :good, :confirmed, :good, :confirmed]
      expect(DataStatus.worst(data_status_array)).to eq('good')
    end

    it 'returns :confirmed when the array includes only :confirmed elements' do
      data_status_array = [:confirmed, :confirmed, :confirmed, :confirmed, :confirmed]
      expect(DataStatus.worst(data_status_array)).to eq('confirmed')
    end

    it 'returns nil when the array is empty' do
      data_status_array = []
      expect(DataStatus.worst(data_status_array)).to be_nil
    end

    it 'returns nil when the provided argument is nil' do
      data_status_array = nil
      expect(DataStatus.worst(data_status_array)).to be_nil
    end

    it 'functions properly if the array consists of strings instead of symbols' do
      data_status_array = %w(good confirmed questionable bad good)
      expect(DataStatus.worst(data_status_array)).to eq('bad')
    end
  end

  describe '.limits' do
    let(:typical_time_in_aid) { DataStatus::TYPICAL_TIME_IN_AID }
    let(:terrain_limit_factors) { DataStatus::LIMIT_FACTORS[:terrain].symbolize_keys }
    let(:in_aid_limit_factors) { DataStatus::LIMIT_FACTORS[:in_aid].symbolize_keys }

    it 'raises an error if type is not recognized' do
      typical_time = 999
      type = :random_type
      expect { DataStatus.limits(typical_time, type) }.to raise_error(/not recognized/)
    end

    it 'returns nil if type is nil' do
      typical_time = 999
      type = nil
      expect(DataStatus.limits(typical_time, type)).to be_nil
    end

    it 'returns nil if typical_time is nil' do
      typical_time = nil
      type = :in_aid
      expect(DataStatus.limits(typical_time, type)).to be_nil
    end

    it 'returns a hash containing zero limits when type is :start' do
      typical_time = 0
      type = :start
      expected = {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0}
      expect(DataStatus.limits(typical_time, type)).to eq(expected)
    end

    it 'returns a hash containing zero lower limits and liberal upper limits when type is :in_aid' do
      typical_time = 5.minutes
      type = :in_aid
      expected = in_aid_limit_factors.transform_values { |factor| factor * (typical_time + typical_time_in_aid) }
      expect(DataStatus.limits(typical_time, type)).to eq(expected)
    end

    it 'returns a hash containing calculated upper and lower limits when type is :terrain' do
      typical_time = 60.minutes
      type = :terrain
      expected = terrain_limit_factors.transform_values { |factor| factor * typical_time }
      expect(DataStatus.limits(typical_time, type)).to eq(expected)
    end
  end

  describe '.determine' do
    it 'returns nil if limits is nil' do
      limits = nil
      seconds = 999
      expect(DataStatus.determine(limits, seconds)).to be_nil
    end

    it 'returns nil if limits is an empty hash' do
      limits = {}
      seconds = 999
      expect(DataStatus.determine(limits, seconds)).to be_nil
    end

    it 'returns nil if seconds is nil' do
      limits = {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0}
      seconds = nil
      expect(DataStatus.determine(limits, seconds)).to be_nil
    end

    it 'returns "good" if seconds is zero and all limits are zero' do
      limits = {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0}
      seconds = 0
      expect(DataStatus.determine(limits, seconds)).to eq('good')
    end

    it 'returns "good" if seconds is between low_questionable and high_questionable' do
      limits = {low_bad: 100, low_questionable: 200, high_questionable: 300, high_bad: 400}
      seconds = 250
      expect(DataStatus.determine(limits, seconds)).to eq('good')
    end

    it 'returns "questionable" if seconds is between low_bad and low_questionable' do
      limits = {low_bad: 100, low_questionable: 200, high_questionable: 300, high_bad: 400}
      seconds = 150
      expect(DataStatus.determine(limits, seconds)).to eq('questionable')
    end

    it 'returns "questionable" if seconds is between high_questionable and high_bad' do
      limits = {low_bad: 100, low_questionable: 200, high_questionable: 300, high_bad: 400}
      seconds = 350
      expect(DataStatus.determine(limits, seconds)).to eq('questionable')
    end

    it 'returns "bad" if seconds is below low_bad' do
      limits = {low_bad: 100, low_questionable: 200, high_questionable: 300, high_bad: 400}
      seconds = 50
      expect(DataStatus.determine(limits, seconds)).to eq('bad')
    end

    it 'returns "bad" if seconds is above high_bad' do
      limits = {low_bad: 100, low_questionable: 200, high_questionable: 300, high_bad: 400}
      seconds = 450
      expect(DataStatus.determine(limits, seconds)).to eq('bad')
    end
  end
end