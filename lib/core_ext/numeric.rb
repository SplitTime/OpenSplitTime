# frozen_string_literal: true

module CoreExt
  module Numeric
    def round_to_nearest(rounding_quotient = 0)
      if rounding_quotient.zero?
        round
      else
        (self / rounding_quotient.to_f).round * rounding_quotient
      end
    end

    def numericize # Parallel to String#numericize
      self
    end
  end
end

class Numeric
  include CoreExt::Numeric
end
