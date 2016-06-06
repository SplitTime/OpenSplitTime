class ControlPanelDisplay

  attr_accessor
  attr_reader :event, :progress_rows
  delegate :name, :start_time, :course, :race, :simple?, to: :event

  # initialize(event)
  # event is an ordinary event object

  def initialize(event)
    @event = event
    @ordered_splits = event.ordered_splits.to_a
    @split_name_hash = Hash[@ordered_splits.map { |split| [split.id, split.base_name] }]
    @bitkey_hashes = @ordered_splits.map(&:sub_split_bitkey_hashes).flatten
    @event_segment_calcs = EventSegmentCalcs.new(event)
    @efforts = event.efforts.sorted_with_finish_status
    @progress_rows = []
    create_progress_rows
  end

  def event_start_time
    event.start_time
  end

  def efforts_started_count
    efforts.count
  end

  def efforts_finished
    efforts.select { |effort| effort.final_split_id == ordered_split_ids.last}
  end

  def efforts_finished_count
    efforts_finished.count
  end

  def efforts_dropped
    efforts.select { |effort| effort.dropped_split_id.present? }
  end

  def efforts_dropped_count
    efforts_dropped.count
  end

  def efforts_in_progress
    efforts.select { |effort| effort.dropped_split_id.nil? && (effort.final_split_id != ordered_split_ids.last)}
  end

  def efforts_in_progress_count
    efforts_in_progress.count
  end

  def efforts_overdue_count
    past_due_progress_rows.count
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  def past_due_progress_rows
    progress_rows.select { |row| row.over_under_due > 0 }.sort_by(&:over_under_due).reverse
  end

  # private

  attr_accessor :efforts, :ordered_splits, :split_name_hash, :bitkey_hashes, :event_segment_calcs

  def create_progress_rows
    efforts_in_progress.each do |effort|
      progress_row = EffortProgressRow.new(effort, event_segment_calcs, split_name_hash, bitkey_hashes, event_start_time)
      progress_rows << progress_row
    end
  end

  def ordered_split_ids
    ordered_splits.map(&:id)
  end

end