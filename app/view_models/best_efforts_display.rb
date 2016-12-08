class BestEffortsDisplay

  attr_accessor :filtered_efforts
  attr_reader :course, :effort_rows
  delegate :name, to: :course
  delegate :distance, :vert_gain, :vert_loss, :events, :earliest_event_date,
           :most_recent_event_date, :begin_id, :end_id, to: :segment


  def initialize(course, params = {})
    @course = course
    @genders_numeric = Effort.genders.keys.include?(params[:gender]) ? [Effort.genders[params[:gender]]] : Effort.genders.values
    set_segment(params)
    get_efforts(params)
    @effort_rows = []
    create_effort_rows
  end

  def all_efforts_count
    all_efforts.count
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def segment_name
    segment.name
  end

  def events_count
    events.where(concealed: false).count
  end

  def segment_is_full_course?
    segment.full_course?
  end

  def gender_text
    case genders_numeric
      when [0]
        'male'
      when [1]
        'female'
      else
        'combined'
    end
  end

  private

  attr_accessor :segment, :all_efforts, :sorted_effort_ids, :sorted_effort_genders, :unsorted_filtered_ids
  attr_reader :genders_numeric

  def set_segment(params)
    split1 = params[:split1].present? ? Split.find(params[:split1]) : course.start_split
    split2 = params[:split2].present? ? Split.find(params[:split2]) : course.finish_split
    splits = [split1, split2].sort_by(&:course_index)
    self.segment = Segment.new(begin_sub_split: splits.first.sub_splits.last,
                               end_sub_split: splits.last.sub_splits.first,
                               begin_split: splits.first,
                               end_split: splits.last)
  end

  def get_efforts(params)
    segment_time_hash = segment.times
    self.all_efforts = Effort.joins(:event)
                           .select('efforts.*, events.start_time')
                           .where(id: segment_time_hash.keys)
                           .where(concealed: false)
                           .to_a
                           .each { |effort| effort.segment_time = segment_time_hash[effort.id] }
                           .sort_by! { |effort| [effort.segment_time, effort.gender, effort.age ? -effort.age : 0] }
    self.sorted_effort_ids = all_efforts.map(&:id)
    self.sorted_effort_genders = all_efforts.map(&:gender)
    self.unsorted_filtered_ids = Effort.where(id: sorted_effort_ids)
                                     .where(gender: genders_numeric)
                                     .search(params[:search])
                                     .ids
    self.filtered_efforts = all_efforts
                                .select { |effort| unsorted_filtered_ids.include?(effort.id) }
                                .paginate(page: params[:page], per_page: 25)
  end

  def create_effort_rows
    filtered_efforts.each do |effort|
      effort_row = EffortRow.new(effort, overall_place: overall_place(effort),
                                 gender_place: gender_place(effort),
                                 start_time: effort.start_time)
      effort_rows << effort_row
    end
  end

  def overall_place(effort)
    sorted_effort_ids.index(effort.id) + 1
  end

  def gender_place(effort)
    sorted_effort_genders[0...overall_place(effort)].count(effort.gender)
  end
end