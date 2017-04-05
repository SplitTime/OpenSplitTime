class BestEffortsDisplay

  attr_reader :course
  delegate :name, to: :course
  delegate :distance, :vert_gain, :vert_loss, :begin_lap, :end_lap,
           :begin_id, :end_id, :begin_bitkey, :end_bitkey, to: :segment

  def initialize(course, params = {})
    @course = course
    @params = params
    @events = Event.where(id: all_efforts.map(&:event_id).uniq, concealed: false).order(start_time: :desc).to_a
    @genders_numeric = Effort.genders[params[:gender]] || Effort.genders.values
  end

  def filtered_efforts
    selected_efforts.paginate(page: params[:page], per_page: 25)
  end

  def selected_efforts
    (params[:gender] != 'combined') | params[:search].present? ?
        all_efforts.select { |effort| filter_ids.include?(effort.id) } :
        all_efforts
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
    segment_is_full_course? ? 'Full Course' : segment.name
  end

  def events_count
    events.size
  end

  def earliest_event_date
    events.last.start_time.to_date.to_formatted_s(:long)
  end

  def latest_event_date
    events.first.start_time.to_date.to_formatted_s(:long)
  end

  def most_recent_event_date
    most_recent_event && most_recent_event.start_time.to_date.to_formatted_s(:long)
  end

  def most_recent_event
    events.select { |event| event.start_time < Time.now }.sort_by(&:start_time).last
  end

  def title_text
    "#{gender_text.upcase} • #{segment_name.upcase}"
  end

  def time_header_text
    segment_is_full_course? ? 'Course Time' : 'Segment Time'
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

  attr_reader :events, :genders_numeric, :params

  def segment
    return @segment if defined?(@segment)
    split1 = params[:split1].present? ? Split.friendly.find(params[:split1]) : course.start_split
    split2 = params[:split2].present? ? Split.friendly.find(params[:split2]) : course.finish_split
    splits = [split1, split2].sort_by(&:course_index)
    @segment = Segment.new(begin_point: TimePoint.new(1, splits.first.id, splits.first.bitkeys.last),
                           end_point: TimePoint.new(1, splits.last.id, splits.last.bitkeys.first))
  end

  def segment_is_full_course?
    segment.full_course?
  end

  def filter_ids
    @filter_ids ||= Effort.where(gender: genders_numeric).search(params[:search]).ids.to_set
  end

  def all_efforts
    @all_efforts ||= Effort.find_by_sql(EffortQuery.over_segment(segment))
  end
end