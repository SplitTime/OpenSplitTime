# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RawTimeFromLiveTime do
  subject { RawTimeFromLiveTime.new(live_time) }

  context 'when a valid live_time is provided' do
    let(:live_time) { build_stubbed(:live_time) }

    it 'creates a raw_time with expected attributes' do
      raw_time = subject.build
      expect(raw_time).to be_a(RawTime)
      expect(raw_time.event_group_id).to eq(live_time.event.event_group_id)
      expect(raw_time.split_name).to eq(live_time.split.base_name)
      expect(raw_time.bib_number).to eq(live_time.bib_number)
    end
  end

  context 'when an object other than a live_time is provided' do
    let(:live_time) { Effort.new }

    it 'raises an error' do
      expect { subject.build }.to raise_error ArgumentError
    end
  end

  context 'when nil is provided' do
    let(:live_time) { nil }

    it 'raises an error' do
      expect { subject.build }.to raise_error ArgumentError
    end
  end
end
