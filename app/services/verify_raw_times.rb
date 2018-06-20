# frozen_string_literal: true

# args[:effort] should be loaded with {split_times: :split} and event

class VerifyRawTimes
  def self.perform(args)
    new(args).perform
  end
  
  def initialize(args)
    ArgsValidator.validate(params: args, required: [:effort, :raw_times], exclusive: [:effort, :raw_times], class: self.class)
    @effort = args[:effort]
    @raw_times = args[:raw_times]
    validate_setup
  end

  def perform

  end
  
  private
  
  attr_reader :effort, :raw_times
  delegate :split_times, :event, to: :effort

  def splits
    split_times.map(&:split)
  end

  def temporary_split_times
    raw_times.map { |raw_time| SplitTimeFromRawTime.build(raw_time) }
  end

  def subject_split
    @subject_split ||= splits.find { |split| split.id == subject_split_id }
  end

  def subject_split_id
    raw_times.first.split_id
  end

  def validate_setup
    raise ArgumentError, 'raw_times must have the same split_id' if raw_times.map(&:split_id).compact.uniq.many?
    raise ArgumentError, 'raw_times must have different bitkeys' unless raw_times.map(&:bitkey) == raw_times.map(&:bitkey).uniq
  end
end
