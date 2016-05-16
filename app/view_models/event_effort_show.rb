class EventEffortShow
  attr_accessor :effort_ids, :vitals, :finish_hash

  def initialize(event)
    @time_array = event.sorted_ultra_time_array
    @effort_ids = @time_array.map { |row| [row[0], row[-1]] }
    @vitals = event.efforts
                  .pluck_to_hash(:id, :bib_number, :first_name, :last_name, :gender, :age, :state_code, :country_code, :dropped)
                  .index_by { |block| block[:id] }
  end

  def create_rows
    effort_ids.each do |id|
      EffortRow.new(id,)
    end
  end

  def finish_hash
    build_hash = Hash[effort_ids]
    dropped_hash = Hash[@vitals.values.map { |block| [block[:id], block[:dropped_split_id]] }].delete_if { |_, v| v.nil? }
    dropped_hash = dropped_hash.each_key { |key| dropped_hash[key] = "DNF" }
    build_hash.merge!(dropped_hash)
    result_hash = {}
    build_hash.each { |k,v| result_hash[k] = v ? v : "In progress" }
    result_hash
  end

end