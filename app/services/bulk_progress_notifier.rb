# frozen_string_literal: true

class BulkProgressNotifier
  def self.notify(split_times)
    new(split_times).notify
  end
  
  def initialize(split_times)
    @split_times = split_times
  end

  def notify
    grouped_ids.each do |effort_id, split_time_ids|
      NotifyProgressJob.perform_later(effort_id, split_time_ids)
    end
  end

  private

  attr_reader :split_times

  def grouped_ids
    split_times.group_by(&:effort_id).transform_values { |split_times| split_times.map(&:id) }
  end
end
