# frozen_string_literal: true

class SegmentTimesContainer

  VALID_CALC_MODELS = [:terrain, :stats, :focused]

  attr_reader :calc_model

  def initialize(args = {})
    ArgsValidator.validate(params: args,
                           exclusive: [:effort_ids, :efforts, :calc_model],
                           class: self.class)
    @effort_ids = args[:effort_ids] || (args[:efforts] && args[:efforts].map(&:id))
    @calc_model = args[:calc_model] || :terrain
    @segment_times = {}
    @limits_hashes = {}
    validate_setup
  end

  def segment_time(segment)
    @segment_times[segment] ||=
        SegmentTimeCalculator.typical_time(segment: segment, effort_ids: effort_ids, calc_model: calc_model)
  end

  def limits(segment)
    @limits_hashes[segment] ||=
        segment_time(segment) ? DataStatus.limits(segment_time(segment), limits_type(segment)) : {}
  end

  def data_status(segment, seconds)
    limits(segment).present? ? DataStatus.determine(limits(segment), seconds) : nil
  end

  private

  attr_reader :effort_ids, :segment_times, :limits_hashes

  def limits_type(segment)
    segment.special_limits_type || calc_model
  end

  def validate_setup
    if calc_model == :focused && effort_ids.nil?
      raise ArgumentError, 'SegmentTimesContainer cannot be initialized with calc_model: :focused unless effort_ids are provided'
    end
    if calc_model && VALID_CALC_MODELS.exclude?(calc_model)
      raise ArgumentError, "calc_model #{calc_model} is not recognized"
    end
  end
end