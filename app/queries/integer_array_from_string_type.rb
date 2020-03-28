# frozen_string_literal: true

class IntegerArrayFromStringType < ::ActiveModel::Type::Value
  def cast(value)
    return super if value.is_a?(Enumerable)

    value.to_s.gsub(/[^\d,]/, "").split(",").map(&:to_i)
  end
end
