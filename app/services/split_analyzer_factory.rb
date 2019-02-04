# frozen_string_literal: true

class SplitAnalyzerFactory
  def self.analyzer(split_analyzable)
    if grouped_splits?(split_analyzable)
      EventGroupSplitAnalyzer.new(split_analyzable)
    else
      SimpleSplitAnalyzer.new(split_analyzable)
    end
  end

  def self.grouped_splits?(split_analyzable)
    split_analyzable.is_a?(EventGroup)
  end
end
