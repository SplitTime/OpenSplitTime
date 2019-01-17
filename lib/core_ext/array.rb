class Array
  def average
    sum / size.to_f
  end

  def elements_before(index_element, inclusive: false)
    i = index(index_element)
    return [] unless i
    i += 1 if inclusive
    self[0, i]
  end

  def elements_after(index_element, inclusive: false)
    i = index(index_element)
    return [] unless i
    i -= 1 if inclusive
    self[(i + 1)..-1]
  end

  def included_before?(index_element, subject_element, inclusive: false)
    elements_before(index_element, inclusive: inclusive).include?(subject_element)
  end

  def included_after?(index_element, subject_element, inclusive: false)
    elements_after(index_element, inclusive: inclusive).include?(subject_element)
  end
end
