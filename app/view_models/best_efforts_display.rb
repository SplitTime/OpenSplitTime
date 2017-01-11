class BestEffortsDisplay

  attr_reader :course
  delegate :name, to: :course
  delegate :distance, :vert_gain, :vert_loss, :begin_id, :end_id, :begin_bitkey, :end_bitkey, to: :segment


  def initialize(course, params = {})
    @course = course
    set_segment(params)
    @events = Event.where(id: all_efforts.map(&:event_id).uniq, concealed: false).order(start_time: :desc).to_a
    @genders_numeric = Effort.genders[params[:gender]] || Effort.genders.values
    @params = params
  end

  def filtered_efforts
    selected_efforts.paginate(page: params[:page], per_page: 25)
  end

  def selected_efforts
    (params[:gender] != 'combined') | params[:search].present? ?
        all_efforts.select { |effort| filter_ids.include?(effort.id) } :
        all_efforts
  end

  def filter_ids
    @filter_ids ||= Effort.where(gender: genders_numeric).search(params[:search]).map(&:id)
  end

  def all_efforts_count
    all_efforts.size
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def effort_rows
    @effort_rows ||= filtered_efforts.map { |effort| EffortRow.new(effort) }
  end

  def segment_name
    segment.name
  end

  def events_count
    events.size
  end

  def segment_is_full_course?
    segment.full_course?
  end

  def earliest_event_date
    events.last.start_time
  end

  def latest_event_date
    events.first.start_time
  end

  def most_recent_event_date
    events.find { |event| event.start_time < Time.now }.start_time
  end

  def gender_text
    case Array.wrap(genders_numeric)
    when [0]
      'male'
    when [1]
      'female'
    else
      'combined'
    end
  end

  private

  attr_accessor :segment
  attr_reader :events, :genders_numeric, :params

  def set_segment(params)
    split1 = params[:split1].present? ? Split.find(params[:split1]) : course.start_split
    split2 = params[:split2].present? ? Split.find(params[:split2]) : course.finish_split
    splits = [split1, split2].sort_by(&:course_index)
    self.segment = Segment.new(begin_sub_split: splits.first.sub_splits.last,
                               end_sub_split: splits.last.sub_splits.first,
                               begin_split: splits.first,
                               end_split: splits.last)
  end

  def all_efforts
    @all_efforts ||= Effort.select('efforts.*, rank() over (order by segment_seconds, gender, -age) as overall_rank, rank() over (partition by gender order by segment_seconds, -age) as gender_rank').from("(#{subquery_segment_seconds.to_sql}) as efforts")
                         .visible.order('overall_rank').to_a
  end

  def subquery_segment_seconds
    Effort.select('e1.*, (tfs_end - tfs_begin) as segment_seconds').from("(#{subquery_base.to_sql}) as e1, (#{subquery_base_join.to_sql}) as e2")
        .where('e1.effort_id = e2.effort_id')
  end

  def subquery_base
    Effort.joins(:split_times).joins(:event)
        .select('efforts.*, events.start_time as query_start_time, split_times.effort_id, split_times.time_from_start as tfs_begin, split_times.split_id, split_times.sub_split_bitkey')
        .where(split_times: {split_id: begin_id, sub_split_bitkey: begin_bitkey})
  end

  def subquery_base_join
    Effort.joins(:split_times).select('efforts.id, split_times.effort_id, split_times.time_from_start as tfs_end, split_times.split_id, split_times.sub_split_bitkey')
        .where(split_times: {split_id: end_id, sub_split_bitkey: end_bitkey})
  end
end