class Array
  def elements_before(element)
    i = index(element)
    i ? self[0, i] : []
  end

  def elements_after(element)
    i = index(element)
    i ? self[(i + 1)..-1] : []
  end
end