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
    it 'returns nil when passed a nil parameter' do
      hms_elapsed = nil
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to be_nil
    end

    it 'returns nil when passed an empty string' do
      hms_elapsed = ''
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to be_nil
    end

    it 'returns zero when passed a string of zeros' do
      hms_elapsed = '00:00:00'
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to eq(0)
    end

    it 'converts a string in the form of hh:mm:ss to seconds' do
      hms_elapsed = '12:30:40'
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to eq(12.hours + 30.minutes + 40.seconds)
    end

    it 'functions properly when passed a time greater than 24 hours' do
      hms_elapsed = '27:30:40'
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to eq(27.hours + 30.minutes + 40.seconds)
    end

    it 'functions properly when passed a time greater than 100 hours' do
      hms_elapsed = '105:30:40'
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to eq(105.hours + 30.minutes + 40.seconds)
    end

    it 'preserves fractional seconds to two decimal places when present' do
      hms_elapsed = '12:30:40.55'
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to eq(12.hours + 30.minutes + 40.55.seconds)
    end

    it 'computes times properly when no hour component is present' do
      hms_elapsed = '05:24.00'
      expect(TimeConversion.hms_to_seconds(hms_elapsed)).to eq((5.minutes + 24.seconds).to_i)
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
    it 'returns an empty string when passed a nil parameter' do
      absolute = nil
      expect(TimeConversion.absolute_to_hms(absolute)).to eq('')
    end

    it 'returns 00:00:00 when passed a date without time values' do
      absolute = Date.new(2016, 1, 1)
      expect(TimeConversion.absolute_to_hms(absolute)).to eq('00:00:00')
    end

    with_each_class do |clazz|
      it 'returns a string in the form of hh:mm:ss when passed a time object' do
        absolute = clazz.new(2016, 7, 1, 6, 30, 45)
        expect(TimeConversion.absolute_to_hms(absolute)).to eq('06:30:45')
      end
    end

    with_each_class do |clazz|
      it 'functions properly when time is past 12:59:59' do
        absolute = clazz.new(2016, 7, 1, 15, 30, 45)
        expect(TimeConversion.absolute_to_hms(absolute)).to eq('15:30:45')
      end
    end

    with_each_class do |clazz|
      it 'functions properly with an ActiveSupport::TimeWithZone object' do
        absolute = clazz.new(2016, 7, 1, 15, 30, 45).in_time_zone
        expected = format('%02d:%02d:%02d', absolute.hour, absolute.min, absolute.sec)
        expect(TimeConversion.absolute_to_hms(absolute)).to eq(expected)
      end
    end

    with_each_class do |clazz|
      it 'functions as expected in different time zones' do
        absolute = clazz.parse('2017-08-01 12:00:00 GMT').in_time_zone('Arizona')
        expected = '05:00:00'
        expect(TimeConversion.absolute_to_hms(absolute)).to eq(expected)
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
end
