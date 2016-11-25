class EffortDataStatusSetter

  def initialize(args)
    ArgsValidator.validate(params: args, required: :effort)
    @effort = args[:effort]
    @split_times = args[:split_times] || effort.split_times
    @times_predictor = args[:times_predictor] || TimesPredictor.new(effort: effort)
  end

  def set_data_status

  end

  private

  attr_reader :effort, :split_times, :times_predictor


end