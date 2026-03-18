class SegmentTimesContainer
  VALID_CALC_MODELS = [:terrain, :stats, :focused].freeze

  attr_reader :calc_model

  def initialize(effort_ids: nil, efforts: nil, calc_model: :terrain)
    @effort_ids = effort_ids || efforts&.map(&:id)
    @calc_model = calc_model
    @segment_times = {}
    @limits_hashes = {}
    validate_setup
  end

  def segment_time(segment)
    return @segment_times[segment] if @segment_times.key?(segment)

    @segment_times[segment] =
      SegmentTimeCalculator.typical_time(segment: segment, effort_ids: effort_ids, calc_model: calc_model)
  end

  def limits(segment)
    return @limits_hashes[segment] if @limits_hashes.key?(segment)

    @limits_hashes[segment] =
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
      raise ArgumentError,
            "SegmentTimesContainer cannot be initialized with calc_model: :focused unless effort_ids are provided"
    end
    return unless calc_model && VALID_CALC_MODELS.exclude?(calc_model)

    raise ArgumentError, "calc_model #{calc_model} is not recognized"
  end
end
