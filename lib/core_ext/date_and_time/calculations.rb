# frozen_string_literal: true

module CoreExt
  module DateAndTime
    module Calculations
      # Given an anniversary date and a compare date, returns the closest anniversary
      # to the compare date.
      #
      # If the anniversary date is February 29, the value returned depends on whether
      # options[:leap_year] is specified as :february, :march, or :strict (default
      # behavior is :february).
      #
      def closest_anniversary(compare_date, options = {})
        leap_year_option = options[:leap_year]&.to_sym || :february

        unless leap_year_option.in?([:strict, :february, :march])
          raise ArgumentError, "options[:leap_year] must be :strict, :february, or :march"
        end

        compare_date = compare_date.to_date
        year_range = leap_year_option == :strict ? 4 : 1

        possible_dates = (-year_range..year_range).map do |offset|
          Date.new(compare_date.year + offset, month, day)
        rescue ArgumentError
          case leap_year_option
          when :february
            Date.new(compare_date.year + offset, 2, 28)
          when :march
            Date.new(compare_date.year + offset, 3, 1)
          else
            nil
          end
        end

        possible_dates.compact.min_by { |date| (compare_date - date).abs }
      end
    end
  end
end

::Date.include ::CoreExt::DateAndTime::Calculations
::DateTime.include ::CoreExt::DateAndTime::Calculations
::ActiveSupport::TimeWithZone.include ::CoreExt::DateAndTime::Calculations
