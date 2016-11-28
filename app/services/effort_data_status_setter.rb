class EffortDataStatusSetter

  def initialize(args)
    ArgsValidator.validate(params: args, required: :effort)
    @effort = args[:effort]
    @split_times = args[:split_times] || effort.ordered_split_times.to_a
    @valid_split_time = split_times.shift
    @times_predictor = args[:times_predictor] || TimesPredictor.new(effort: effort)
  end

  def set_data_status
    split_times.each { |split_time| set_split_time_data_status(split_time) }
  end

  private

  attr_reader :effort, :split_times, :times_predictor
  attr_accessor :valid_split_time

  def set_split_time_data_status(split_time)
    split_time.data_status = times_predictor
  end

end