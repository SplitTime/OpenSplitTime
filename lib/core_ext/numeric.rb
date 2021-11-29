class Numeric
  def round_to_nearest(rounding_quotient = 0)
    rounding_quotient.zero? ?
        self.round :
        (self / rounding_quotient.to_f).round * rounding_quotient
  end

  def numericize # Parallel to String#numericize
    self
  end
end