class CrewAccessBoardDisplay
  Controls = Struct.new(:buffer, :sort_order, :hide_departed, :hide_passed, :search, keyword_init: true)

  DEFAULT_SORT = "release".freeze

  def initialize(gating_location_event:, buffer: nil, sort: nil, hide_departed: nil, hide_passed: nil, search: nil)
    @gating_location_event = gating_location_event
    @controls = Controls.new(
      buffer: buffer.presence&.to_i&.clamp(0, 1200) || gating_location_event.default_travel_buffer,
      sort_order: sort.presence || DEFAULT_SORT,
      hide_departed: ActiveModel::Type::Boolean.new.cast(hide_departed),
      hide_passed: ActiveModel::Type::Boolean.new.cast(hide_passed),
      search: search.presence,
    )
  end

  attr_reader :gating_location_event, :controls

  delegate :event, :gating_location, to: :gating_location_event
  delegate :event_group, :name, to: :gating_location
  delegate :buffer, to: :controls

  # Runners who have passed the gating aid station, filtered and sorted per the controls
  def rows
    @rows ||= sort_rows(filter_rows(build_rows))
  end

  private

  def build_rows
    passed_efforts.map do |effort|
      GatingLocationRow.new(effort: effort, gating_location_event: gating_location_event,
                            crew_passage: crew_passages_by_effort[effort.id])
    end
  end

  def filter_rows(rows)
    rows = rows.reject(&:departed_target?) if controls.hide_departed
    rows = rows.reject(&:crew_passed?) if controls.hide_passed
    rows = rows.select { |row| row_matches_search?(row) } if controls.search.present?
    rows
  end

  def row_matches_search?(row)
    query = controls.search.downcase.strip
    row.bib_number.to_s.include?(query) || row.full_name.downcase.include?(query)
  end

  def sort_rows(rows)
    if controls.sort_order == "release"
      rows.sort_by { |row| row.release_sort_key(controls.buffer) }
    else
      rows.sort_by { |row| row.bib_number.to_i }
    end
  end

  def crew_passages_by_effort
    @crew_passages_by_effort ||= gating_location.crew_passages.index_by(&:effort_id)
  end

  def passed_efforts
    effort_ids = SplitTime.where(split_id: gating_location_event.gating_split.id,
                                 effort_id: event.efforts.select(:id))
                          .distinct.pluck(:effort_id)
    Effort.where(id: effort_ids).includes(split_times: :split)
  end
end
