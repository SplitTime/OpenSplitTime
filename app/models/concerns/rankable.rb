# frozen_string_literal: true

# This module provides ranking methods for presenters.
# An implementing class must respond to overall_rank, gender_rank,
# and the various status booleans (started?, in_progress?, dropped?)
# that are typical for an effort.

module Rankable
  extend ActiveSupport::Concern

  def display_overall_rank
    started? ? overall_rank : '--'
  end

  def display_gender_rank
    started? ? gender_rank : '--'
  end

  def effort_status
    case
    when finished?
      'Finished'
    when dropped?
      'Dropped'
    when in_progress?
      'In Progress'
    else
      'Not Started'
    end
  end
end
