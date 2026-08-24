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

    typical_time = segment_time(segment)
    @limits_hashes[segment] =
      if typical_time.nil? || (!typical_time.positive? && scaling_limits_type?(segment))
        {}
      else
        DataStatus.limits(typical_time, limits_type(segment))
      end
  end

  def data_status(segment, seconds)
    limits(segment).present? ? DataStatus.determine(limits(segment), seconds) : nil
  end

  private

  attr_reader :effort_ids, :segment_times, :limits_hashes

  def limits_type(segment)
    segment.special_limits_type || calc_model
  end

  # zero_start bands are intentionally all-zero, and in_aid adds a fixed
  # positive allowance, so a zero typical time still yields a usable band
  # for those types; all others scale purely with the typical time
  def scaling_limits_type?(segment)
    !limits_type(segment).to_s.in?(%w[zero_start in_aid])
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
