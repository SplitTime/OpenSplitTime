# frozen_string_literal: true

# This module provides tools to build and analyze split names
# and to build a split_name_dropdown menu.

# An implementing class must respond to event_group or override split_analyzable.
# To take advantage of split_name and the prior_ and next_ methods,
# it must also respond to parameterized_split_name.

module SplitAnalyzable
  extend ActiveSupport::Concern

  delegate :ordered_split_names, :parameterized_split_names, :splits_by_event, to: :split_analyzer

  def split_name
    parameterized_split_name_map[parameterized_split_name]
  end

  def prior_parameterized_split_name
    parameterized_split_names.element_before(parameterized_split_name)
  end

  def next_parameterized_split_name
    parameterized_split_names.element_after(parameterized_split_name)
  end

  def prior_split_name
    parameterized_split_name_map[prior_parameterized_split_name]
  end

  def next_split_name
    parameterized_split_name_map[next_parameterized_split_name]
  end

  private

  def parameterized_split_name_map
    parameterized_split_names.zip(ordered_split_names).to_h
  end

  def split_analyzable
    event_group
  end

  def split_analyzer
    @split_analyzer ||= SplitAnalyzerFactory.analyzer(split_analyzable)
  end
end
