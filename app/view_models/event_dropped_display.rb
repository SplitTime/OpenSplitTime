class EventDroppedDisplay
  attr_reader :event
  delegate :name, :start_time, :course, :organization, :simple?, :beacon_url, :available_live, to: :event

  def initialize(args)
    @event = args[:event]
    @params = args[:params] || {}
  end

  def effort_rows
    dropped_efforts.map { |effort| EffortRow.new(effort: effort) }
  end

  def efforts_count
    started_efforts.size
  end

  def dropped_efforts_count
    dropped_efforts.size
  end

  private

  attr_reader :params

  def sort_fields
    params[:sort]&.to_unsafe_hash || {}
  end

  def started_efforts
    @started_efforts ||= event.efforts.ranked_with_finish_status(sort: sort_fields) # This scope ignores efforts having no split_times.
  end

  def dropped_efforts
    @dropped_efforts ||= started_efforts.select(&:dropped?)
  end
end
