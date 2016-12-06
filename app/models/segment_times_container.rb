class SegmentTimesContainer

  VALID_CALC_MODELS = [:terrain, :stats, :focused]

  def initialize(args = {})
    ArgsValidator.validate(params: args,
                           exclusive: [:effort_ids, :efforts, :calc_model],
                           class: self.class)
    @effort_ids = args[:effort_ids] || (args[:efforts] && args[:efforts].map(&:id))
    @calc_model = args[:calc_model] || :terrain
    @segment_time_calculators = {}
    validate_setup
  end

  def []=(segment, time_calculator)
    segment_time_calculators[segment] = time_calculator
  end

  def [](segment)
    segment_time_calculators[segment] ||=
        SegmentTimeCalculator.new(segment: segment, effort_ids: effort_ids, calc_model: calc_model)
  end

  def segment_time(segment)
    self[segment].calculated_time
  end

  def data_status(segment, seconds)
    self[segment].data_status(seconds)
  end

  def limits(segment)
    self[segment].limits
  end

  private

  attr_reader :effort_ids, :segment_time_calculators, :calc_model

  def validate_setup
    if calc_model == :focused && effort_ids.nil?
      raise ArgumentError, 'SegmentTimesContainer cannot be initialized with calc_model: :focused unless effort_ids are provided'
    end
    if calc_model && VALID_CALC_MODELS.exclude?(calc_model)
      raise ArgumentError, "calc_model #{calc_model} is not recognized"
    end
  end
end