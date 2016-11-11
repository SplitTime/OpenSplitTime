class String
  def numeric?
    true if Float(self) rescue false
  end
end