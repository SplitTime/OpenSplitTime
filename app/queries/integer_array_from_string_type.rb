# frozen_string_literal: true

class IntegerArrayFromStringType < ::ActiveModel::Type::Value
  def cast(value)
    value.gsub(/[^\d,]/, "").split(",").map(&:to_i)
  end
end
