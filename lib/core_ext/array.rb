class Array
  def elements_before(index_element)
    i = index(index_element)
    i ? self[0, i] : []
  end

  def elements_after(index_element)
    i = index(index_element)
    i ? self[(i + 1)..-1] : []
  end

  def included_before?(index_element, subject_element)
    i = index(index_element)
    i ? self[0, i].include?(subject_element) : false
  end

  def included_after?(index_element, subject_element)
    i = index(index_element)
    i ? self[(i + 1)..-1].include?(subject_element) : false
  end
end