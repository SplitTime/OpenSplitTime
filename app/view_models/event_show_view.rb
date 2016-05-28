class EventShowView
  # extend ActiveSupport::Concern

  attr_reader :event, :efforts, :effort_data, :effort_ids, :filtered_efforts_count
  delegate :name, :start_time, :course, :race, :simple?, to: :event

  def initialize(event, params)
    @event = event
    calculate_time_array(event)
    get_efforts_and_raw_data(params)
    @effort_data = effort_data_raw.index_by { |block| block[:id] }
    @effort_ids = effort_data_raw.map { |block| block[:id] }
    calculate_finish_hash(time_array)
  end

  def effort_row(effort_id)
    EffortRow.new(self, effort_id)
  end

  def event_efforts_count
    sorted_event_effort_ids.count
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  def overall_place(effort_id)
    sorted_event_effort_ids.index(effort_id) + 1
  end

  def finish_status(effort_id)
    finish_hash[effort_id]
  end

  private

  attr_accessor :time_array, :finish_hash, :effort_data_raw, :sorted_event_effort_ids

  def get_efforts_and_raw_data(params)
    @efforts = event.efforts
                   .search(params[:search_param])
                   .sorted(time_array)
                   .paginate(page: params[:page], per_page: 25)
    self.effort_data_raw = efforts.map { |effort| {id: effort.id,
                                                   bib_number: effort.bib_number,
                                                   first_name: effort.first_name,
                                                   last_name: effort.last_name,
                                                   gender: effort.gender,
                                                   age: effort.age,
                                                   state_code: effort.state_code,
                                                   country_code: effort.country_code,
                                                   dropped_split_id: effort.dropped_split_id,
                                                   data_status: effort.data_status} }
    @filtered_efforts_count = efforts.total_entries
  end

  def calculate_time_array(event)
    self.time_array = event.sorted_ultra_time_array
    self.sorted_event_effort_ids = time_array.map { |row| row[0] }
  end

  def calculate_finish_hash(time_array)
    limited_time_array = time_array.keep_if { |row| effort_data.keys.include?(row[0]) }
    build_hash = Hash[limited_time_array.map { |row| [row[0], row[-1]] }]
    dropped_hash = Hash[effort_data.values.map { |block| [block[:id], block[:dropped_split_id]] }].delete_if { |_, v| v.nil? }
    dropped_hash = dropped_hash.each_key { |key| dropped_hash[key] = "DNF" }
    build_hash.merge!(dropped_hash)
    result_hash = {}
    build_hash.each { |k, v| result_hash[k] = v ? v : "In progress" }
    self.finish_hash = result_hash
  end

end