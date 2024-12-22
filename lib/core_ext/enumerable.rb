# frozen_string_literal: true

module CoreExt
  module EnumerableExtensions
    def count_by(&block)
      Hash[group_by(&block).map { |k, v| [k, v.size] }]
    end

    def count_each
      count_by { |e| e }
    end

    def each_with_iteration
      Enumerator.new do |y|
        iteration = 1
        enum = cycle
        loop do
          enum.peek # raises StopIteration if self.empty?
          size.times do
            e = [enum.next, iteration]
            y << (block_given? ? yield(e) : e)
          end
          iteration += 1
        end
      end
    end

    def group_by_equality(&block)
      result = {}
      each do |element|
        proposed_key = block.call(element)
        existing_key = result.keys.find { |key| key == proposed_key }
        existing_key ? result[existing_key] << element : result[proposed_key] = [element]
      end
      result
    end
  end
end

module Enumerable
  include CoreExt::EnumerableExtensions
end
