# Postgres returns an array_agg field as a comma-delimited String
# surrounded by curly braces, like "{hello,there,world}".
#
# This Type converts such a String to an array of Strings.
#
module Type
  class StringArrayFromString < ::ActiveModel::Type::Value
    # @param [String, Array, nil] value
    # @return [Array<String>]
    def cast(value)
      return super if value.is_a?(Enumerable)
      return [] if value.blank?

      stripped_value = value.to_s.match(/\A{(.*)}\z/)[1]
      return [] if stripped_value.blank?

      stripped_value.split(",")
    end
  end
end
