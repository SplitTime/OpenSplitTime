require "rails_helper"

RSpec.describe TimeConversion do
  before(:context) do
    ENV["TZ"] = "UTC"
  end

  after(:context) do
    ENV["TZ"] = nil
  end

  describe ".hms_to_seconds" do
    let(:result) { described_class.hms_to_seconds(hms_elapsed) }

    context "when passed a nil parameter" do
      let(:hms_elapsed) { nil }
      it { expect(result).to be_nil }
    end

    context "when passed an empty string" do
      let(:hms_elapsed) { "" }
      it { expect(result).to be_nil }
    end

    context "when passed a string of zeros" do
      let(:hms_elapsed) { "00:00:00" }
      it { expect(result).to eq(0) }
    end

    context "when passed hours, minutes, and seconds in hh:mm:ss format" do
      let(:hms_elapsed) { "12:30:40" }
      it { expect(result).to eq(12.hours + 30.minutes + 40.seconds) }
    end

    context "when passed a time greater than 24 hours" do
      let(:hms_elapsed) { "27:30:40" }
      it { expect(result).to eq(27.hours + 30.minutes + 40.seconds) }
    end

    context "when passed a time greater than 100 hours" do
      let(:hms_elapsed) { "105:30:40" }
      it { expect(result).to eq(105.hours + 30.minutes + 40.seconds) }
    end

    context "when decimals are present" do
      let(:hms_elapsed) { "12:30:40.55" }
      it { expect(result).to eq(12.hours + 30.minutes + 40.55.seconds) }
    end

    context "when no seconds component is present" do
      let(:hms_elapsed) { "05:24" }
      it { expect(result).to eq((5.hours + 24.minutes).to_i) }
    end

    context "with a negative time with 00 hours component" do
      let(:hms_elapsed) { "-00:30:00" }
      it { expect(result).to eq(-1800) }
    end

    context "with a negative time with an hours component" do
      let(:hms_elapsed) { "-01:30:00" }
      it { expect(result).to eq(-5400) }
    end

    context "when provided an incorrect format" do
      let(:hms_elapsed) { "1:0:30" }
      it { expect { result }.to raise_error ArgumentError, /Improper hms time format/ }
    end

    context "when provided non-numeric data" do
      let(:hms_elapsed) { "Sat 07:00:00" }
      it { expect { result }.to raise_error ArgumentError, /Improper hms time format/ }
    end
  end

  describe ".seconds_to_hms" do
    let(:result) { described_class.seconds_to_hms(seconds) }

    context "when passed a nil parameter" do
      let(:seconds) { nil }
      it { expect(result).to eq("") }
    end

    context "when passed zero" do
      let(:seconds) { 0 }
      it { expect(result).to eq("00:00:00") }
    end

    context "when passed an integer number of seconds" do
      let(:seconds) { 4545 }
      it { expect(result).to eq("01:15:45") }
    end

    context "for times in excess of 24 hours" do
      let(:seconds) { 100_000 }
      it { expect(result).to eq("27:46:40") }
    end

    context "for times in excess of 100 hours" do
      let(:seconds) { 500_000 }
      it { expect(result).to eq("138:53:20") }
    end

    context "when two decimal places are present" do
      let(:seconds) { 4545.67 }
      it { expect(result).to eq("01:15:45.67") }
    end
  end

  describe ".absolute_to_hms" do
    let(:result) { described_class.absolute_to_hms(absolute) }
    let(:absolute) { time_string.in_time_zone }

    context "when passed nil" do
      let(:absolute) { nil }
      it("returns an empty string") { expect(result).to eq("") }
    end

    context "when passed an empty string" do
      let(:absolute) { "" }
      it("returns an empty string") { expect(result).to eq("") }
    end

    context "when passed a time in the morning" do
      let(:time_string) { "2016-07-01 06:30:45" }
      it { expect(result).to eq("06:30:45") }
    end

    context "when time is past 12:59:59" do
      let(:time_string) { "2016-07-01 15:30:45" }
      it { expect(result).to eq("15:30:45") }
    end

    context "when time is in a time zone other than UTC" do
      let(:absolute) { "2017-08-01 05:00:00".in_time_zone("Arizona") }
      it { expect(result).to eq("05:00:00") }
    end
  end

  describe ".user_entered_to_military" do
    let(:result) { described_class.user_entered_to_military(time_string) }

    context "when provided as a timestamp" do
      let(:time_string) { "2022-07-15 06:34:12-0600" }
      it { expect(result).to eq("06:34:12") }
    end

    context "when provided in hh:mm:ss format" do
      let(:time_string) { "12:30:45" }
      it { expect(result).to eq("12:30:45") }
    end

    context "when provided in hh:mm format" do
      let(:time_string) { "12:30" }
      it { expect(result).to eq("12:30:00") }
    end

    context "when provided in h:mm:ss format" do
      let(:time_string) { "2:30:45" }
      it { expect(result).to eq("02:30:45") }
    end

    context "when provided in h:mm format" do
      let(:time_string) { "2:30" }
      it { expect(result).to eq("02:30:00") }
    end

    context "substitutes zeros for non-numeric characters at the end of the string" do
      let(:time_string) { "12:30:ss" }
      it { expect(result).to eq("12:30:00") }
    end

    context "when non-numeric characters are in the middle of the string" do
      let(:time_string) { "12:mm:30" }
      it { expect(result).to eq("12:00:30") }
    end

    context "when non-numeric characters are at the beginning of the string" do
      let(:time_string) { "hh:30:00" }
      it { expect(result).to eq("00:30:00") }
    end

    context "when the hours provided is out of range" do
      let(:time_string) { "24:00:00" }
      it { expect(result).to be_nil }
    end

    context "when the minutes provided is out of range" do
      let(:time_string) { "12:60:00" }
      it { expect(result).to be_nil }
    end

    context "when the seconds provided is out of range" do
      let(:time_string) { "12:00:60" }
      it { expect(result).to be_nil }
    end

    context "when time provided is an empty string" do
      let(:time_string) { "" }
      it { expect(result).to be_nil }
    end

    context "when time provided is less than three characters in length" do
      let(:time_string) { "12" }
      it { expect(result).to be_nil }
    end

    context "when time provided is an invalid timestamp" do
      let(:time_string) { "2025-16-08 05:01:55" }
      it { expect(result).to be_nil }
    end
  end

  describe ".valid_military?" do
    let(:result) { described_class.valid_military?(time_string) }

    context "when provided in a valid format" do
      context "with hh:mm:ss" do
        let(:time_string) { "10:10:10" }
        it { expect(result).to eq(true) }
      end

      context "with midnight" do
        let(:time_string) { "00:00:00" }
        it { expect(result).to eq(true) }
      end

      context "with edge of day" do
        let(:time_string) { "23:59:59" }
        it { expect(result).to eq(true) }
      end

      context "with hh:mm" do
        let(:time_string) { "12:34" }
        it { expect(result).to eq(true) }
      end

      context "with padded single-digit hour" do
        let(:time_string) { "01:00:00" }
        it { expect(result).to eq(true) }
      end

      context "with hh:mm padded" do
        let(:time_string) { "01:00" }
        it { expect(result).to eq(true) }
      end

      context "with single-digit hour and full seconds" do
        let(:time_string) { "1:00:00" }
        it { expect(result).to eq(true) }
      end

      context "with single-digit hour and minutes only" do
        let(:time_string) { "1:00" }
        it { expect(result).to eq(true) }
      end
    end

    context "when provided in an invalid format" do
      context "with hour out of range" do
        let(:time_string) { "24:00:00" }
        it { expect(result).to eq(false) }
      end

      context "with minute out of range" do
        let(:time_string) { "00:60:00" }
        it { expect(result).to eq(false) }
      end

      context "with second out of range" do
        let(:time_string) { "00:00:60" }
        it { expect(result).to eq(false) }
      end

      context "with negative time" do
        let(:time_string) { "-10:10:10" }
        it { expect(result).to eq(false) }
      end

      context "with trailing colon" do
        let(:time_string) { "12:00:" }
        it { expect(result).to eq(false) }
      end

      context "with incomplete time" do
        let(:time_string) { "12:" }
        it { expect(result).to eq(false) }
      end

      context "with invalid minutes format" do
        let(:time_string) { "1:0:00" }
        it { expect(result).to eq(false) }
      end

      context "with invalid seconds format" do
        let(:time_string) { "1:00:0" }
        it { expect(result).to eq(false) }
      end

      context "with three-digit hour" do
        let(:time_string) { "100:00:00" }
        it { expect(result).to eq(false) }
      end

      context "with three-digit minute" do
        let(:time_string) { "10:000:00" }
        it { expect(result).to eq(false) }
      end

      context "with three-digit second" do
        let(:time_string) { "10:00:000" }
        it { expect(result).to eq(false) }
      end
    end
  end
end
