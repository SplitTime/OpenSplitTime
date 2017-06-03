class BulkFollowerNotifier

  def initialize(split_times, options)
    @split_time_ids = split_times.map(&:id)
    @multi_lap = options[:multi_lap]
  end

  def notify
    id_hash.each do |participant_id, split_time_ids|
      NotifyFollowersJob.perform_now(participant_id: participant_id, split_time_ids: split_time_ids, multi_lap: multi_lap)
    end
  end

  private

  attr_reader :split_time_ids, :multi_lap

  def id_hash
    @id_hash ||= SplitTime.where(id: split_time_ids).joins(:effort).select('split_times.id, efforts.participant_id')
                     .pluck(:id, :participant_id).group_by { |_, participant_id| participant_id }
                     .map { |participant_id, array| [participant_id, array.map(&:first)] }.to_h
  end
end
