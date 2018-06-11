# frozen_string_literal: true

class RawTimeFromLiveTime
  IDENTICAL_ATTRIBUTES = %i[bitkey bib_number absolute_time entered_time with_pacer stopped_here source pulled_by pulled_at created_by updated_by remarks]

  def self.build(live_time)
    new(live_time).build
  end

  def initialize(live_time)
    @live_time = live_time
    raise ArgumentError unless live_time.is_a?(LiveTime)
  end

  def build
    raw_time = RawTime.new(event_group_id: live_time.event.event_group_id,
                           split_time_id: live_time.split_time_id,
                           split_name: live_time.split&.base_name || '[Unknown]')
    IDENTICAL_ATTRIBUTES.each { |attr| raw_time[attr] = live_time.send(attr) }

    raw_time
  end

  private

  attr_reader :live_time
end
