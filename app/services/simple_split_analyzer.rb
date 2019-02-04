# frozen_string_literal: true

class SimpleSplitAnalyzer
  def initialize(split_analyzable)
    @split_analyzable = split_analyzable
  end

  def parameterized_split_names
    @parameterized_split_names ||= split_analyzable.ordered_splits.map(&:parameterized_base_name)
  end

  def ordered_split_names
    @ordered_split_names ||= split_analyzable.ordered_splits.map(&:base_name)
  end

  private

  attr_reader :split_analyzable
end
