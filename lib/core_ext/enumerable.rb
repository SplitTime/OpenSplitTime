module Enumerable
  def count_by(&block)
    Hash[group_by(&block).map { |k, v| [k, v.count] }]
  end

  def count_each
    each_with_object(Hash.new(0)) { |e, acc| acc[e] += 1 }
  end
end