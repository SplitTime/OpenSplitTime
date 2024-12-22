# frozen_string_literal: true

module CoreExt
  module String
    def numeric?
      true if Float(self)
    rescue StandardError
      false
    end

    def numericize
      gsub(/[^\d.]/, "").to_f
    end

    def to_boolean
      ActiveRecord::Type::Boolean.new.cast(self)
    end

    alias to_bool to_boolean
  end
end

class String
  include CoreExt::String
end
