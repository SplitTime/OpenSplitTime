class SegmentTimeCalculator

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

  def calculated_time
    @calculated_time ||=
        case calc_model
        when :focused
          segment.typical_time_by_stats(effort_ids)
        when :stats
          segment.typical_time_by_stats
        else
          segment.typical_time_by_terrain
        end
  end

  def data_status(seconds)
    DataStatus.determine(limits, seconds)
  end

  def limits
    DataStatus.limits(calculated_time, limits_type)
  end

  private

  attr_reader :segment, :effort_ids, :calc_model

  def limits_type
    segment.special_limits_type || calc_model
  end

  def validate_setup
    if calc_model == :focused && effort_ids.nil?
      raise ArgumentError, 'SegmentTimesContainer cannot be initialized with calc_model: :focused unless effort_ids are provided'
    end
    if calc_model && SegmentTimesContainer::VALID_CALC_MODELS.exclude?(calc_model)
      raise ArgumentError, "calc_model #{calc_model} is not recognized"
    end
  end
end