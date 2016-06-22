class LiveEffortData

  attr_accessor :time_from_start_in, :time_from_start_out, :time_from_prior_valid, :last_day_and_time,
                :time_in_aid, :dropped, :finished, :last_split, :last_bitkey,
                :time_in_exists, :time_out_exists, :split_time_in, :split_time_out,
                :prior_valid_day_and_time, :prior_valid_split, :prior_valid_bitkey, :dropped_here,
                :dropped_split, :dropped_day_and_time
  attr_reader :effort, :response_row

  def initialize(event, params, calcs = nil, ordered_split_array = nil)
    @calcs = calcs || EventSegmentCalcs.new(event)
    @ordered_splits = ordered_split_array || event.ordered_splits.to_a
    @response_row = params.symbolize_keys.slice(:splitId, :bibNumber, :timeIn, :timeOut,
                                                :pacerIn, :pacerOut, :droppedHere)
    @effort = event.efforts.find_by_bib_number(@response_row[:bibNumber])
    set_response_attributes if @effort
    verify_time_existence if (@effort && @split)
    set_dropped_attributes if @effort
    verify_time_status if (@effort && @split)
  end

  def success?
    (effort.present? && split.present?)
  end

  def split_id
    split ? split.id : nil
  end

  def split_name
    split ? split.base_name : nil
  end

  def split_distance
    split ? split.distance_from_start : nil
  end

  def effort_id
    effort ? effort.id : nil
  end

  def effort_name
    effort ? effort.full_name : nil
  end

  def clean?
    times_will_not_overwrite? && times_valid?
  end

  def time_in_status
    split_time_in ? split_time_in.data_status : nil
  end

  def time_out_status
    split_time_out ? split_time_out.data_status : nil
  end

  private

  attr_accessor :split_times_hash, :split, :day_and_time_in, :day_and_time_out, :pacer_in, :pacer_out
  attr_reader :calcs, :ordered_splits

  def set_response_attributes
    self.split = ordered_splits.find { |split| split.id == response_row[:splitId].to_i }
    self.day_and_time_in = (effort && split && response_row[:timeIn].present?) ? effort.likely_intended_time(response_row[:timeIn], split, calcs) : nil
    self.day_and_time_out = (effort && split && response_row[:timeOut].present?) ? effort.likely_intended_time(response_row[:timeOut], split, calcs) : nil
    self.pacer_in = response_row[:pacerIn] = (response_row[:pacerIn].try(&:downcase) == 'true')
    self.pacer_out = response_row[:pacerOut] = (response_row[:pacerOut].try(&:downcase) == 'true')
    self.dropped_here = response_row[:droppedHere] = (response_row[:droppedHere].try(&:downcase) == 'true')
    last_split_time = effort.last_reported_split_time
    if last_split_time
      self.last_day_and_time = effort.start_time + last_split_time.time_from_start
      self.last_split = last_split_time.split
      self.last_bitkey = last_split_time.sub_split_bitkey
    end
    self.finished = effort.finished?
    self.time_from_start_in = day_and_time_in ? day_and_time_in - effort.start_time : nil
    self.time_from_start_out = day_and_time_out ? day_and_time_out - effort.start_time : nil
    self.time_in_aid = (time_from_start_out && time_from_start_in) ? time_from_start_out - time_from_start_in : nil
    self.response_row[:splitName] = split_name
    self.response_row[:effortName] = effort_name
    self.response_row[:splitDistance] = split_distance
  end

  def verify_time_existence

    # Get all the split_times for this effort, which may or may not include
    # existing split_times corresponding to the effort + split being verified

    self.split_times_hash = effort.split_times.index_by(&:bitkey_hash)
    bitkey_hash_in = {split_id => SubSplit::IN_BITKEY}
    bitkey_hash_out = {split_id => SubSplit::OUT_BITKEY}

    # Set 'exists' booleans based on whether times for this effort + split
    # already exist in the database

    self.time_in_exists = self.response_row[:timeInExists] = split_times_hash[bitkey_hash_in].present?
    self.time_out_exists = self.response_row[:timeOutExists] = split_times_hash[bitkey_hash_out].present?

  end

  def set_dropped_attributes
    self.dropped = effort.dropped?
    if dropped
      self.dropped_split = ordered_splits.find { |split| split.id == effort.dropped_split_id }
      bitkey_hash_in = dropped_split ? {dropped_split.id => SubSplit::IN_BITKEY} : nil
      bitkey_hash_out = dropped_split ? {dropped_split.id => SubSplit::OUT_BITKEY} : nil
      dropped_split_time = split_times_hash[bitkey_hash_out] || split_times_hash[bitkey_hash_in]
      self.dropped_day_and_time = dropped_split_time ? effort.start_time + dropped_split_time.time_from_start : nil
    end
  end

  def verify_time_status

    # Build in and/or out SplitTime instances (depending on availability of time data)
    # to determine status of entered times.

    self.split_time_in = time_from_start_in ?
        SplitTime.new(effort_id: effort_id,
                      split_id: split_id,
                      sub_split_bitkey: SubSplit::IN_BITKEY,
                      time_from_start: time_from_start_in,
                      pacer: pacer_in) :
        nil
    self.split_time_out = time_from_start_out ?
        SplitTime.new(effort_id: effort.id,
                      split_id: split_id,
                      sub_split_bitkey: SubSplit::OUT_BITKEY,
                      time_from_start: time_from_start_out,
                      pacer: pacer_out) :
        nil
    bitkey_hash_in = split_time_in ? split_time_in.bitkey_hash : nil
    bitkey_hash_out = split_time_out ? split_time_out.bitkey_hash : nil

    # Now insert new SplitTime instances (if any) into hash table (or change existing ones)

    split_times_hash[bitkey_hash_in] = split_time_in if split_time_in
    split_times_hash[bitkey_hash_out] = split_time_out if split_time_out

    # Use ordered_bitkey_hashes as a framework to collect split_times into correct order

    ordered_bitkey_hashes = ordered_splits.map(&:sub_split_bitkey_hashes).flatten
    ordered_split_times = ordered_bitkey_hashes.collect { |key_hash| split_times_hash[key_hash] }

    # Now determine data status of each object in the ordered split_time group,
    # including the new in and/or out SplitTime instances

    status_hash = DataStatusService.live_entry_data_status(effort, ordered_splits, ordered_split_times.compact, calcs)
    valid_status_hash = status_hash.select { |_, status| status == 'good' }
    prior_bitkey_hashes = ordered_splits[0..ordered_splits.index(split) - 1].map(&:sub_split_bitkey_hashes).flatten
    prior_valid_bitkey_hash = prior_bitkey_hashes
                                  .collect { |bitkey_hash| [bitkey_hash, valid_status_hash[bitkey_hash]] }
                                  .select { |e| e[1].present? }
                                  .last[0]
    prior_valid_split_time = split_times_hash[prior_valid_bitkey_hash]
    self.prior_valid_day_and_time = prior_valid_split_time ? effort.start_time + prior_valid_split_time.time_from_start : nil
    self.prior_valid_split = prior_valid_split_time ? prior_valid_split_time.split : nil
    self.prior_valid_bitkey = prior_valid_split_time ? prior_valid_split_time.sub_split_bitkey : nil
    self.time_from_prior_valid = (time_from_start_in && prior_valid_split_time) ? time_from_start_in - prior_valid_split_time.time_from_start : nil

    # And save the data status of the new SplitTime instances and response_rows

    self.split_time_in.data_status = self.response_row[:timeInStatus] = status_hash[bitkey_hash_in] if split_time_in
    self.split_time_out.data_status = self.response_row[:timeOutStatus] = status_hash[bitkey_hash_out] if split_time_out
  end

  def times_will_not_overwrite?
    time_in_exists != true && time_out_exists != true
  end

  def times_valid?
    ((time_in_status == 'good') || time_in_status.nil?) &&
        ((time_out_status == 'good') || time_out_status.nil?)
  end

end
