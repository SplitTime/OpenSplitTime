# frozen_string_literal: true

# Postgres returns an array_agg field as a comma-delimited String
# surrounded by curly braces, like "{1,2,3}".
#
# This Type converts such a String to an array of integers.
#
module Type
  class IntegerArrayFromString < ::ActiveModel::Type::Value
    # @param [String, Array, nil] value
    # @return [Array<Integer>]
    def cast(value)
      return super if value.is_a?(Enumerable)

      value.to_s.gsub(/[^\d,]/, "").split(",").map(&:to_i)
    end
  end
end
