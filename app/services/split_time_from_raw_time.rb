class SplitTimeFromRawTime
  def self.build(raw_time, args)
    effort = args[:effort]
    event = args[:event]

    identical_attributes = [:effort_id, :lap, :split_id, :bitkey, :with_pacer, :stopped_here, :remarks]
    split_time = SplitTime.new(identical_attributes.map { |attr| [attr, raw_time.send(attr)] }.to_h)
    effort.event = event
    split_time.effort = effort

    if raw_time.absolute_time?
      split_time.day_and_time = raw_time.absolute_time
    else
      split_time.military_time = raw_time.military_time
    end

    split_time
  end
end
