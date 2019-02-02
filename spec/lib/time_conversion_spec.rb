# frozen_string_literal: true

require_relative '../../lib/time_conversion'
require 'date'
require 'active_support/all'

RSpec.describe TimeConversion do
  before(:context) do
    ENV['TZ'] = 'UTC'
  end

  after(:context) do
    ENV['TZ'] = nil
  end

  def self.with_each_class(&block)
    classes = [Time, DateTime]

    classes.each do |clazz|
      context "with a #{clazz.name} class" do
        instance_exec clazz, &block
      end
    end
  end

  describe '.hms_to_seconds' do
    subject { TimeConversion.hms_to_seconds(hms_elapsed) }

    context 'when passed a nil parameter' do
      let(:hms_elapsed) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when passed an empty string' do
      let(:hms_elapsed) { '' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when passed a string of zeros' do
      let(:hms_elapsed) { '00:00:00' }

      it 'returns zero' do
        expect(subject).to eq(0)
      end
    end

    context 'when passed hours, minutes, and seconds in hh:mm:ss format' do
      let(:hms_elapsed) { '12:30:40' }

      it 'converts the string to seconds' do
        expect(subject).to eq(12.hours + 30.minutes + 40.seconds)
      end
    end

    context 'when passed a time greater than 24 hours' do
      let(:hms_elapsed) { '27:30:40' }

      it 'functions properly' do
        expect(subject).to eq(27.hours + 30.minutes + 40.seconds)
      end
    end

    context 'when passed a time greater than 100 hours' do
      let(:hms_elapsed) { '105:30:40' }

      it 'functions properly' do
        expect(subject).to eq(105.hours + 30.minutes + 40.seconds)
      end
    end

    context 'when decimals are present' do
      let(:hms_elapsed) { '12:30:40.55' }

      it 'preserves fractional seconds to two decimal places' do
        expect(subject).to eq(12.hours + 30.minutes + 40.55.seconds)
      end
    end

    context 'when no seconds component is present' do
      let(:hms_elapsed) { '05:24' }

      it 'computes times properly' do
        expect(subject).to eq((5.hours + 24.minutes).to_i)
      end
    end

    context 'with a negative time with 00 hours component' do
      let(:hms_elapsed) { '-00:30:00' }

      it 'computes seconds properly' do
        expect(subject).to eq(-1800)
      end
    end

    context 'with a negative time with an hours component' do
      let(:hms_elapsed) { '-01:30:00' }

      it 'computes seconds properly' do
        expect(subject).to eq(-5400)
      end
    end

    context 'when provided an incorrect format' do
      let(:hms_elapsed) { '1:0:30' }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError, /Improper hms time format/
      end
    end

    context 'when provided non-numeric data' do
      let(:hms_elapsed) { 'Sat 07:00:00' }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError, /Improper hms time format/
      end
    end
  end

  describe '.seconds_to_hms' do
    it 'returns an empty string when passed a nil parameter' do
      seconds = nil
      expect(TimeConversion.seconds_to_hms(seconds)).to eq('')
    end

    it 'returns 00:00:00 when passed zero' do
      seconds = 0
      expect(TimeConversion.seconds_to_hms(seconds)).to eq('00:00:00')
    end

    it 'returns a string in the form of hh:mm:ss when passed an integer number of seconds' do
      seconds = 4545
      expect(TimeConversion.seconds_to_hms(seconds)).to eq('01:15:45')
    end

    it 'functions properly for times in excess of 24 hours' do
      seconds = 100000
      expect(TimeConversion.seconds_to_hms(seconds)).to eq('27:46:40')
    end

    it 'functions properly for times in excess of 100 hours' do
      seconds = 500000
      expect(TimeConversion.seconds_to_hms(seconds)).to eq('138:53:20')
    end

    it 'preserves fractional seconds to two decimal places when present' do
      seconds = 4545.67
      expect(TimeConversion.seconds_to_hms(seconds)).to eq('01:15:45.67')
    end
  end

  describe '.absolute_to_hms' do
    subject { TimeConversion.absolute_to_hms(absolute) }

    context 'when passed nil' do
      let(:absolute) { nil }
      it('returns an empty string') { expect(subject).to eq('') }
    end

    context 'when passed a date without time values' do
      let(:absolute) { Date.new(2016, 1, 1) }
      it('returns 00:00:00') { expect(subject).to eq('00:00:00') }
    end

    with_each_class do |clazz|
      context 'when passed a time object' do
        let(:absolute) { clazz.new(2016, 7, 1, 6, 30, 45) }
        it('returns a string in the form of hh:mm:ss') { expect(subject).to eq('06:30:45') }
      end
    end

    with_each_class do |clazz|
      context 'when time is past 12:59:59' do
        let(:absolute) { clazz.new(2016, 7, 1, 15, 30, 45) }
        it('returns a string in the form of hh:mm:ss') { expect(subject).to eq('15:30:45') }
      end
    end

    with_each_class do |clazz|
      context 'when time is an ActiveSupport::TimeWithZone object' do
        let(:absolute) { clazz.new(2016, 7, 1, 15, 30, 45).in_time_zone }
        it('functions properly') { expect(subject).to eq(format('%02d:%02d:%02d', absolute.hour, absolute.min, absolute.sec)) }
      end
    end

    with_each_class do |clazz|
      context 'when time is in different time zones' do
        let(:absolute) { clazz.parse('2017-08-01 12:00:00 GMT').in_time_zone('Arizona') }
        it('functions properly') { expect(subject).to eq('05:00:00') }
      end
    end
  end

  describe '.file_to_military' do
    it 'returns time in hh:mm:ss format when provided in hh:mm:ss format' do
      file_string = '12:30:45'
      expected = '12:30:45'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'returns time in hh:mm:ss format with :00 for seconds when provided in hh:mm format' do
      file_string = '12:30'
      expected = '12:30:00'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'returns time in hh:mm:ss format with a leading zero when provided in h:mm:ss format' do
      file_string = '2:30:45'
      expected = '02:30:45'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'returns time in hh:mm:ss format with a leading zero and :00 for seconds when provided in h:mm format' do
      file_string = '2:30'
      expected = '02:30:00'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'properly determines colon insertion points when time is provided in hhmmss format' do
      file_string = '123045'
      expected = '12:30:45'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'properly determines colon insertion points when time is provided in hhmm format' do
      file_string = '1230'
      expected = '12:30:00'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'properly determines colon insertion points when time is provided in hmmss format' do
      file_string = '23045'
      expected = '02:30:45'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'properly determines colon insertion points when time is provided in hmm format' do
      file_string = '230'
      expected = '02:30:00'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'ignores non-numeric characters at the end of the string' do
      file_string = '12:30:xx'
      expected = '12:30:00'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'ignores non-numeric characters in the middle of the string' do
      file_string = '12abc30'
      expected = '12:30:00'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'ignores non-numeric characters at the beginning of the string' do
      file_string = 'joe123000'
      expected = '12:30:00'
      expect(TimeConversion.file_to_military(file_string)).to eq(expected)
    end

    it 'returns nil when the hours provided is out of range' do
      file_string = '24:00:00'
      expect(TimeConversion.file_to_military(file_string)).to be_nil
    end

    it 'returns nil when the minutes provided is out of range' do
      file_string = '12:60:00'
      expect(TimeConversion.file_to_military(file_string)).to be_nil
    end

    it 'returns nil when the seconds provided is out of range' do
      file_string = '12:00:60'
      expect(TimeConversion.file_to_military(file_string)).to be_nil
    end

    it 'returns nil when time provided is an empty string' do
      file_string = ''
      expect(TimeConversion.file_to_military(file_string)).to be_nil
    end

    it 'returns nil when time provided is less than three characters in length' do
      file_string = '12'
      expect(TimeConversion.file_to_military(file_string)).to be_nil
    end
  end

  describe '.valid_military?' do
    context 'when provided in a valid format' do
      let(:time_strings) { %w(10:10:10 00:00:00 23:59:59 12:34 01:00:00 01:00 1:00:00 1:00) }

      it 'returns true' do
        time_strings.each do |time_string|
          expect(TimeConversion.valid_military?(time_string)).to eq(true)
        end
      end
    end

    context 'when provided in an invalid format' do
      let(:time_strings) { %w(24:00:00 00:60:00 00:00:60 -10:10:10 12:00: 12: 1:0:00 1:00:0 100:00:00 10:000:00 10:00:000) }

      it 'returns false' do
        time_strings.each do |time_string|
          expect(TimeConversion.valid_military?(time_string)).to eq(false)
        end
      end
    end
  end
end
