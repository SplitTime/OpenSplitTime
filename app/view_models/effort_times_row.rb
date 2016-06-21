class EffortTimesRow

  include PersonalInfo

  attr_reader :effort, :time_clusters
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :place, to: :effort

  def initialize(effort, splits, split_times, options = {})
    @effort = effort
    @splits = splits
    @split_times = split_times.index_by(&:bitkey_hash)
    @start_time_from_params = options[:start_time]
    @time_clusters = []
    create_time_clusters
  end

  private

  attr_reader :splits, :split_times, :start_time_from_params

  def effective_start_time
    start_time_from_params.try(:to_datetime) || effort.start_time
  end

  def create_time_clusters
    prior_time = 0
    splits.each do |split|
      time_cluster = TimeCluster.new(split,
                                     related_split_times(split),
                                     prior_time,
                                     effective_start_time)
      time_clusters << time_cluster
      prior_time = time_cluster.times_from_start.compact.last if time_cluster.times_from_start.compact.present?
    end
  end

  def related_split_times(split)
    split.sub_split_bitkey_hashes.collect { |bitkey_hash| split_times[bitkey_hash] }
  end

end