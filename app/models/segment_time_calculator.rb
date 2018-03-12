# frozen_string_literal: true

class SegmentTimeCalculator

  DISTANCE_FACTOR = 0.6 # Multiply distance in meters by this factor to approximate normal travel time on foot
  VERT_GAIN_FACTOR = 4.0 # Multiply vert_gain in meters by this factor to approximate normal travel time on foot
  STATS_CALC_THRESHOLD = 4

  def self.typical_time(args)
    new(args).typical_time
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:segment, :calc_model],
                           exclusive: [:segment, :effort_ids, :calc_model],
                           class: self.class)
    @segment = args[:segment]
    @effort_ids = args[:effort_ids]
    @calc_model = args[:calc_model]
    validate_setup
  end

  def typical_time
    case calc_model
    when :focused
      typical_time_by_stats(effort_ids)
    when :stats
      typical_time_by_stats
    else
      typical_time_by_terrain
    end
  end

  private

  attr_reader :segment, :effort_ids, :calc_model

  def typical_time_by_terrain
    (segment.distance * DISTANCE_FACTOR) + (segment.vert_gain * VERT_GAIN_FACTOR)
  end

  def typical_time_by_stats(effort_ids = nil)
    return nil if effort_ids == [] # Empty array indicates an attempt for a focused query without any focus efforts
    segment_time, effort_count = SplitTimeQuery.typical_segment_time(segment, effort_ids)
    effort_count >= STATS_CALC_THRESHOLD ? segment_time : nil
  end

  def validate_setup
    if calc_model == :focused && effort_ids.nil?
      raise ArgumentError, 'SegmentTimeCalculator cannot be initialized with calc_model: :focused unless effort_ids are provided'
    end
    if calc_model && SegmentTimesContainer::VALID_CALC_MODELS.exclude?(calc_model)
      raise ArgumentError, "calc_model #{calc_model} is not recognized"
    end
  end
end