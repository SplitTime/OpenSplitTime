class ExpectedLapFinder

  def self.lap(args)
    new(args).lap
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:ordered_split_times, :split],
                           exclusive: [:ordered_split_times, :split],
                           class: self.class)
    @ordered_split_times = args[:ordered_split_times]
    @split = args[:split]
  end

  def lap
    return 1 unless latest_time_group.present?
    latest_group_complete? ? latest_lap + 1 : latest_lap
  end

  private

  attr_reader :ordered_split_times, :split

  def latest_group_complete?
    latest_split_times.size == split.bitkeys.size
  end

  def latest_lap
    latest_time_group.first
  end

  def latest_split_times
    latest_time_group.last
  end

  def latest_time_group
    @latest_time_group ||= existing_times_on_split.group_by(&:lap).max_by { |lap, _| lap }
  end

  def existing_times_on_split
    ordered_split_times.select { |st| st.split_id == split.id }
  end
end