class String
  def numeric?
    true if Float(self) rescue false
  end

  def numericize
     self.gsub(/[^\d\.]/, '').to_f
  end
end