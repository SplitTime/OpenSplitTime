# frozen_string_literal: true

class BulkFollowerNotifier

  def initialize(split_times, options)
    @split_time_ids = split_times.map(&:id)
    @multi_lap = options[:multi_lap]
  end

  def notify
    id_hash.each do |person_id, split_time_ids|
      NotifyFollowersJob.perform_later(person_id: person_id, split_time_ids: split_time_ids, multi_lap: multi_lap)
    end
  end

  private

  attr_reader :split_time_ids, :multi_lap

  def id_hash
    @id_hash ||= SplitTime.where(id: split_time_ids).joins(:effort).select('split_times.id, efforts.person_id')
                     .pluck(:id, :person_id).group_by { |_, person_id| person_id }
                     .map { |person_id, array| [person_id, array.map(&:first)] }.to_h
  end
end
