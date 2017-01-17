module Enumerable
  def count_by(&block)
    Hash[group_by(&block).map { |k, v| [k, v.size] }]
  end

  def count_each
    count_by { |e| e }
  end

  def each_with_iteration
    Enumerator.new do |y|
      iteration = 1
      enum = self.cycle
      loop do
        enum.peek # raises StopIteration if self.empty?
        self.size.times do
          e = [enum.next, iteration]
          y << (block_given? ? yield(e) : e)
        end
        iteration += 1
      end
    end
  end
end