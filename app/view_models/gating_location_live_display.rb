class GatingLocationLiveDisplay
  Controls = Struct.new(:buffer, :sort_order, :hide_departed, :hide_passed, :search, keyword_init: true)

  DEFAULT_SORT = "release".freeze

  def initialize(gating_location:, adjusted_event_id: nil, adjusted_buffer: nil,
                 sort: nil, hide_departed: nil, hide_passed: nil, search: nil)
    @gating_location = gating_location
    @adjusted_event_id = adjusted_event_id.to_i
    @adjusted_buffer = adjusted_buffer.presence&.to_i&.clamp(0, 1200)
    @adjusted_sort = sort.presence
    @adjusted_hide_departed = ActiveModel::Type::Boolean.new.cast(hide_departed)
    @adjusted_hide_passed = ActiveModel::Type::Boolean.new.cast(hide_passed)
    @adjusted_search = search.presence
  end

  attr_reader :gating_location

  delegate :name, :event_group, to: :gating_location

  def gated_events
    @gated_events ||= gating_location.gating_location_events
                                     .sort_by { |gle| gle.event.guaranteed_short_name }
  end

  # The controls in effect for one gated event: the steward's just-submitted values when they changed
  # this event's controls, otherwise defaults (saved buffer, release-time sort, no filters).
  def controls_for(gating_location_event)
    if gating_location_event.id == adjusted_event_id
      Controls.new(
        buffer: adjusted_buffer || gating_location_event.default_travel_buffer,
        sort_order: adjusted_sort || DEFAULT_SORT,
        hide_departed: adjusted_hide_departed,
        hide_passed: adjusted_hide_passed,
        search: adjusted_search,
      )
    else
      Controls.new(buffer: gating_location_event.default_travel_buffer, sort_order: DEFAULT_SORT,
                   hide_departed: false, hide_passed: false, search: nil)
    end
  end

  def buffer_for(gating_location_event)
    controls_for(gating_location_event).buffer
  end

  # Rows for one gated event: runners who have passed the gating aid station, filtered and sorted
  # per the event's controls.
  def rows_for(gating_location_event)
    controls = controls_for(gating_location_event)
    rows = build_rows(gating_location_event)
    rows = filter_rows(rows, controls)
    sort_rows(rows, controls)
  end

  private

  attr_reader :adjusted_event_id, :adjusted_buffer, :adjusted_sort, :adjusted_hide_departed,
              :adjusted_hide_passed, :adjusted_search

  def build_rows(gating_location_event)
    passed_efforts(gating_location_event).map do |effort|
      GatingLocationRow.new(effort: effort, gating_location_event: gating_location_event,
                            crew_passage: crew_passages_by_effort[effort.id])
    end
  end

  def filter_rows(rows, controls)
    rows = rows.reject(&:departed_target?) if controls.hide_departed
    rows = rows.reject(&:crew_passed?) if controls.hide_passed
    rows = rows.select { |row| row_matches_search?(row, controls.search) } if controls.search.present?
    rows
  end

  def row_matches_search?(row, search)
    query = search.downcase.strip
    row.bib_number.to_s.include?(query) || row.full_name.downcase.include?(query)
  end

  def sort_rows(rows, controls)
    if controls.sort_order == "release"
      rows.sort_by { |row| row.release_sort_key(controls.buffer) }
    else
      rows.sort_by { |row| row.bib_number.to_i }
    end
  end

  def crew_passages_by_effort
    @crew_passages_by_effort ||= gating_location.crew_passages.index_by(&:effort_id)
  end

  def passed_efforts(gating_location_event)
    effort_ids = SplitTime.where(split_id: gating_location_event.gating_split.id,
                                 effort_id: gating_location_event.event.efforts.select(:id))
                          .distinct.pluck(:effort_id)
    Effort.where(id: effort_ids).includes(split_times: :split)
  end
end
