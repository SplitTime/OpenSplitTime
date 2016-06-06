class EffortProgressRow
  include PersonalInfo

  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, to: :effort

  def initialize(effort, event_segment_calcs, split_name_hash, bitkey_hashes, event_start_time)
    @effort = effort
    @event_segment_calcs = event_segment_calcs
    @split_name_hash = split_name_hash
    @bitkey_hashes = bitkey_hashes
    @bitkey_hash = {effort.final_split_id => effort.sub_split_bitkey}
    @start_time = event_start_time + effort.start_offset
  end

  def over_under_due
    Time.now - due_next_day_and_time
  end

  def due_next_split_name
    split_name_hash[due_next_split_id]
  end

  private

  def due_next_day_and_time
    start_time + due_next_time_from_start
  end

  def due_next_time_from_start
    effort.expected_time_from_start(due_next_bitkey_hash, event_segment_calcs)
  end

  def due_next_split_id
    due_next_bitkey_hash.keys.first
  end

  def due_next_bitkey_hash
    bitkey_hashes[bitkey_hashes.index(bitkey_hash) + 1]
  end

  attr_reader :effort, :event_segment_calcs, :start_time, :bitkey_hashes, :bitkey_hash, :split_name_hash

end