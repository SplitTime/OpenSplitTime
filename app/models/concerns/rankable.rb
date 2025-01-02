# This module provides ranking methods for presenters.
# An implementing class must respond to overall_rank, gender_rank,
# and the various status booleans (started?, in_progress?, dropped?)
# that are typical for an effort.

module Rankable
  extend ActiveSupport::Concern

  # @return [String (frozen)]
  def display_overall_rank
    beyond_start? ? overall_rank : "--"
  end

  # @return [String (frozen)]
  def display_gender_rank
    beyond_start? ? gender_rank : "--"
  end

  # @return [String (frozen)]
  def effort_status
    if finished?
      "Finished"
    elsif dropped?
      "Dropped"
    elsif in_progress?
      "In Progress"
    else
      "Not Started"
    end
  end
end
