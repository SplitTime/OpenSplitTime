class SplitTimeFromRawTime
  def self.build(raw_time, effort:, event:, lap: nil)
    identical_attributes = [:effort_id, :lap, :split_id, :bitkey, :with_pacer, :stopped_here, :remarks]
    split_time = SplitTime.new(identical_attributes.map { |attr| [attr, raw_time.send(attr)] }.to_h)
    effort.event = event
    split_time.effort = effort
    split_time.lap ||= lap

    if raw_time.absolute_time?
      split_time.absolute_time = raw_time.absolute_time
    else
      split_time.military_time = raw_time.military_time
    end

    split_time
  end
end
