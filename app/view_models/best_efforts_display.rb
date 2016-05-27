class BestEffortsDisplay
  attr_reader :course, :efforts, :gender, :effort_data, :effort_ids, :filtered_efforts_count
  delegate :name, to: :course
  delegate :distance, :vert_gain, :vert_loss, :events, :earliest_event_date,
           :latest_event_date, :begin_id, :end_id, to: :segment


  def initialize(course, params)
    @course = course
    @gender = params[:gender] || 'combined'
    set_segment(params)
    get_efforts_and_raw_data(params)
    set_overall_and_gender_sorts
    calculate_finish_hash(segment_time_hash, params[:gender])
  end

  def effort_row(effort_id)
    EffortRow.new(self, effort_id)
  end

  def segment_name
    segment.name
  end

  def events_count
    events.count
  end

  def segment_efforts_count
    segment_time_hash.count
  end

  def segment_is_full_course?
    segment.is_full_course?
  end

  def overall_place(effort_id)
    overall_sorted_effort_ids.index(effort_id) + 1
  end

  def gender_place(effort_id)
    gender_sorted_effort_ids[effort_data[effort_id][:gender]].index(effort_id) + 1
  end

  def finish_time(effort_id)
    finish_hash[effort_id]
  end

  private

  attr_accessor :segment, :finish_hash, :segment_time_hash, :effort_data_raw, :overall_sorted_effort_ids, :gender_sorted_effort_ids

  def set_segment(params)
    split1 = params[:split1].present? ? Split.find(params[:split1]) : course.start_split
    split2 = params[:split2].present? ? Split.find(params[:split2]) : course.finish_split
    splits = [split1, split2].sort_by(&:course_index)
    @segment = Segment.new(splits[0], splits[1])
  end

  def get_efforts_and_raw_data(params)
    @efforts = Effort.gender_group(segment, gender)
                   .sorted_by_segment_time(segment)
                   .paginate(page: params[:page], per_page: 25)
    self.effort_data_raw = efforts.map { |effort| {id: effort.id,
                                                   first_name: effort.first_name,
                                                   last_name: effort.last_name,
                                                   gender: effort.gender,
                                                   age: effort.age,
                                                   state_code: effort.state_code,
                                                   country_code: effort.country_code,
                                                   data_status: effort.data_status,
                                                   year: effort.event.start_time.year} }
    @filtered_efforts_count = efforts.total_entries
    @effort_data = effort_data_raw.index_by { |block| block[:id] }
    @effort_ids = effort_data_raw.map { |block| block[:id] }
  end

  def set_overall_and_gender_sorts
    @segment_time_hash = segment.times
    @overall_sorted_effort_ids = segment_time_hash.to_a.sort_by { |x| x[1] }.map { |x| x[0] }
    male_course_effort_ids = Effort.on_course(course).male.pluck(:id)
    female_course_effort_ids = Effort.on_course(course).female.pluck(:id)
    @gender_sorted_effort_ids = {}
    @gender_sorted_effort_ids['male'] = overall_sorted_effort_ids.dup
                                            .keep_if { |effort_id| male_course_effort_ids.include?(effort_id) }
    @gender_sorted_effort_ids['female'] = overall_sorted_effort_ids.dup
                                            .keep_if { |effort_id| female_course_effort_ids.include?(effort_id) }
  end

  def calculate_finish_hash(finish_times, gender)
    relevant_times = finish_times.keep_if { |key, _| sort_in_use(gender).include?(key) }
    self.finish_hash = relevant_times
  end

  def sort_in_use(gender)
    case gender
      when 'male'
        gender_sorted_effort_ids['male']
      when 'female'
        gender_sorted_effort_ids['female']
      else
        overall_sorted_effort_ids
    end
  end

end