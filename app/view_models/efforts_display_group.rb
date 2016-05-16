class EffortsDisplayGroup
  attr_reader :sorted_effort_ids, :effort_data, :finish_hash

  def initialize(event, efforts)
    effort_data_raw = efforts.map { |effort| {id: effort.id,
                                              bib_number: effort.bib_number,
                                              first_name: effort.first_name,
                                              last_name: effort.last_name,
                                              gender: effort.gender,
                                              age: effort.age,
                                              state_code: effort.state_code,
                                              country_code: effort.country_code,
                                              dropped_split_id: effort.dropped_split_id,
                                              data_status: effort.data_status} }
    @effort_data = effort_data_raw.index_by { |block| block[:id] }
    time_array = event.sorted_ultra_time_array
    @sorted_effort_ids = time_array.map { |row| row[0] }
    @finish_hash = calculate_finish_hash(time_array)
  end

  def place(effort_id)
    sorted_effort_ids.index(effort_id) + 1
  end

  def finish_status(effort_id)
    finish_hash[effort_id]
  end

  def effort_row(effort_id)
    EffortRow.new(self, effort_id)
  end

  def calculate_finish_hash(time_array)
    limited_time_array = time_array.keep_if { |row| effort_data.keys.include?(row[0]) }
    build_hash = Hash[limited_time_array.map { |row| [row[0], row[-1]] }]
    dropped_hash = Hash[effort_data.values.map { |block| [block[:id], block[:dropped_split_id]] }].delete_if { |_, v| v.nil? }
    dropped_hash = dropped_hash.each_key { |key| dropped_hash[key] = "DNF" }
    build_hash.merge!(dropped_hash)
    result_hash = {}
    build_hash.each { |k, v| result_hash[k] = v ? v : "In progress" }
    result_hash
  end

end