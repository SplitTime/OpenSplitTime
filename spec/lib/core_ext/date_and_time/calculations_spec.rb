# frozen_string_literal: true

require_relative "../../../rails_helper"
require "core_ext/date_and_time/calculations"

RSpec.describe ::CoreExt::DateAndTime::Calculations do
  describe ".closest_anniversary" do
    non_leap_year_examples =
      [
        {anniversary_date: "2020-07-15", compare_date: "2020-07-15", expected: "2020-07-15"},
        {anniversary_date: "1990-07-15", compare_date: "2020-07-15", expected: "2020-07-15"},
        {anniversary_date: "1990-07-15", compare_date: "2020-12-31", expected: "2020-07-15"},
        {anniversary_date: "1990-07-15", compare_date: "2020-01-31", expected: "2020-07-15"},
        {anniversary_date: "1990-07-15", compare_date: "2020-01-01", expected: "2019-07-15"},
        {anniversary_date: "1990-12-25", compare_date: "2020-01-01", expected: "2019-12-25"},
        {anniversary_date: "1990-01-05", compare_date: "2020-12-31", expected: "2021-01-05"},
        {anniversary_date: "1990-07-15", compare_date: "0001-01-01", expected: "0000-07-15"},
        {anniversary_date: "1990-07-15", compare_date: "0001-07-01", expected: "0001-07-15"},
      ]

    shared_examples "returns the expected result" do |anniversary_date, compare_date, expected|
      subject { anniversary_date.closest_anniversary(compare_date, options) }
      it "returns the expected result" do
        expect(subject).to eq(expected)
      end
    end

    shared_examples "works for all date classes" do |example|
      anniversary_date = example[:anniversary_date]
      compare_date = example[:compare_date]
      expected = example[:expected]

      context "when arguments are Date objects" do
        context "for anniversary date #{anniversary_date} and compare date #{compare_date}" do
          include_examples "returns the expected result",
                           anniversary_date.to_date,
                           compare_date.to_date,
                           expected.to_date
        end
      end

      context "when arguments are Datetime objects" do
        context "for anniversary date #{anniversary_date} and compare date #{compare_date}" do
          include_examples "returns the expected result",
                           anniversary_date.to_datetime,
                           compare_date.to_datetime,
                           expected.to_date
        end
      end

      context "when arguments are ActiveSupport::TimeWithZone objects" do
        context "for anniversary date #{anniversary_date} and compare date #{compare_date}" do
          include_examples "returns the expected result",
                           Date.parse(anniversary_date).in_time_zone("Arizona"),
                           Date.parse(compare_date).in_time_zone("Arizona"),
                           expected.to_date
        end
      end
    end

    context "when leap year option is not specified or is specified as :february" do
      examples = non_leap_year_examples +
        [
          {anniversary_date: "2000-02-29", compare_date: "2020-02-01", expected: "2020-02-29"},
          {anniversary_date: "2000-02-29", compare_date: "2018-02-01", expected: "2018-02-28"},
          {anniversary_date: "2000-02-29", compare_date: "2018-02-28", expected: "2018-02-28"},
          {anniversary_date: "2000-02-29", compare_date: "2018-03-01", expected: "2018-02-28"},
          {anniversary_date: "2000-02-29", compare_date: "1900-02-01", expected: "1900-02-28"},
        ]

      context "not specified" do
        let(:options) { {} }
        examples.each do |example|
          include_examples "works for all date classes", example
        end
      end

      context ":february" do
        let(:options) { {leap_year: :february} }
        examples.each do |example|
          include_examples "works for all date classes", example
        end
      end
    end

    context "when leap year option is :march" do
      let(:options) { {leap_year: :march} }
      examples = non_leap_year_examples +
        [
          {anniversary_date: "2000-02-29", compare_date: "2020-02-01", expected: "2020-02-29"},
          {anniversary_date: "2000-02-29", compare_date: "2018-02-01", expected: "2018-03-01"},
          {anniversary_date: "2000-02-29", compare_date: "2018-02-28", expected: "2018-03-01"},
          {anniversary_date: "2000-02-29", compare_date: "2018-03-01", expected: "2018-03-01"},
          {anniversary_date: "2000-02-29", compare_date: "1900-02-01", expected: "1900-03-01"},
        ]

      examples.each do |example|
        include_examples "works for all date classes", example
      end
    end

    context "when leap year option is strict" do
      let(:options) { {leap_year: :strict} }
      examples = non_leap_year_examples +
        [
          {anniversary_date: "2000-02-29", compare_date: "2020-02-01", expected: "2020-02-29"},
          {anniversary_date: "2000-02-29", compare_date: "2018-02-01", expected: "2016-02-29"},
          {anniversary_date: "2000-02-29", compare_date: "2018-02-28", expected: "2016-02-29"},
          {anniversary_date: "2000-02-29", compare_date: "2018-03-01", expected: "2020-02-29"},
          {anniversary_date: "2000-02-29", compare_date: "1900-02-01", expected: "1896-02-29"},
        ]

      examples.each do |example|
        include_examples "works for all date classes", example
      end
    end
  end
end
