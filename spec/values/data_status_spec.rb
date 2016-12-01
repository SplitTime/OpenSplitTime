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

    it 'functions properly if the array consists of strings instead of symbols' do
      data_status_array = %w(good confirmed questionable bad good)
      expect(DataStatus.worst(data_status_array)).to eq('bad')
    end
  end
end