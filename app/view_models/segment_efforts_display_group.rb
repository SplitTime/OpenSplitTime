class SegmentEffortsDisplayGroup
  attr_reader :sorted_effort_ids, :effort_data, :finish_hash
  attr_accessor :overall_sorted_effort_ids, :sorted_effort_ids

  def initialize(segment, gender, efforts)
    effort_data_raw = efforts.map { |effort| {id: effort.id,
                                              first_name: effort.first_name,
                                              last_name: effort.last_name,
                                              gender: effort.gender,
                                              age: effort.age,
                                              state_code: effort.state_code,
                                              country_code: effort.country_code,
                                              data_status: effort.data_status,
                                              year: effort.event.first_start_time.year} }
    @effort_data = effort_data_raw.index_by { |block| block[:id] }
    finish_times = SegmentCalculations.new(segment).times
    @overall_sorted_effort_ids = finish_times.to_a.sort_by { |x| x[1] }.map { |x| x[0] }
    @sorted_effort_ids = calculate_gender_sort(overall_sorted_effort_ids, gender)
    @finish_hash = calculate_finish_hash(finish_times)
  end

  def place(effort_id)
    overall_sorted_effort_ids.index(effort_id) + 1
  end

  def gender_place(effort_id)
    sorted_effort_ids.index(effort_id) + 1
  end

  def finish_time(effort_id)
    finish_hash[effort_id]
  end

  def effort_row(effort_id)
    EffortRow.new(self, effort_id)
  end

  def calculate_gender_sort(overall_sorted, gender)
    case gender
      when 'male'
        gender_effort_ids = Effort.male.pluck(:id)
      when 'female'
        gender_effort_ids = Effort.female.pluck(:id)
      else
        return overall_sorted
    end
    overall_sorted.keep_if { |effort_id| gender_effort_ids.include?(effort_id) }
    overall_sorted
  end

  def calculate_finish_hash(finish_times)
    finish_times.keep_if { |key, _| sorted_effort_ids.include?(key) }
  end

end