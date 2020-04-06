class SplitTimeFromRawTime
  # TODO: This method should be called only when a the raw time is complete, meaning
  # among other things that it has an absolute_time. But currently this method is called
  # by VerifyRawTimeRow, which does not guarantee presence of an absolute_time. Once that
  # is changed, the conditional `if raw_time.absolute_time?` should be removed.
  def self.build(raw_time, args)
    effort = args[:effort]
    event = args[:event]

    identical_attributes = [:effort_id, :lap, :split_id, :bitkey, :with_pacer, :stopped_here, :remarks]
    split_time = SplitTime.new(identical_attributes.map { |attr| [attr, raw_time.send(attr)] }.to_h)
    effort.event = event
    split_time.effort = effort

    if raw_time.absolute_time?
      split_time.absolute_time = raw_time.absolute_time
    else
      split_time.military_time = raw_time.military_time
    end

    split_time
  end
end
