# frozen_string_literal: true

class VerifyTimeRecords
  def self.perform(args)
    new(args).perform
  end
  
  def initialize(args)
    ArgsValidator.validate(params: args, required: [:effort, :time_records], exclusive: [:effort, :time_records], class: self.class)
    @effort = args[:effort]
    @time_records = args[:time_records]
    validate_setup
  end
  
  def perform
    find_expected_laps
  end
  
  private
  
  attr_reader :effort, :time_records
  delegate :split_times, :event, to: :effort

  def computed_lap
    case
    when event.laps_required == 1 then 1
    when subject_split.null_record? || effort.null_record? then nil
    else
      military_time = params[:time_in] || params[:time_out] || ''
      bitkey = (!params[:time_in] && params[:time_out]) ? SubSplit::OUT_BITKEY : SubSplit::IN_BITKEY
      FindExpectedLap.perform(effort: effort, military_time: military_time, split_id: subject_split.id, bitkey: bitkey)
    end
  end

  def splits
    split_times.map(&:split)
  end

  def temporary_split_times
    time_records.map { |time_record| SplitTimeFromTimeRecord.build(time_record) }
  end

  def subject_split
    @subject_split ||= splits.find { |split| split.id == subject_split_id }
  end

  def subject_split_id

  end

  def validate_setup
    raise ArgumentError, 'raw_times must have the same split_id' if raw_times.map(&:split_id).compact.uniq.many?
    raise ArgumentError, 'raw_times must have different bitkeys' unless raw_times.map(&:bitkey) == raw_times.map(&:bitkey).uniq
  end
end
