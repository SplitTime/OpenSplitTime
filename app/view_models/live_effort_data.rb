class LiveEffortData

  attr_accessor :time_from_start_in, :time_from_start_out, :time_from_last, :last_day_and_time,
                :time_in_aid, :dropped, :finished, :last_split, :last_bitkey,
                :time_in_exists, :time_out_exists, :time_in_status, :time_out_status,
                :existing_time_in_id, :existing_time_out_id
  attr_reader :effort

  def initialize(event, params, calcs = nil, ordered_split_array = nil)
    @calcs = calcs || EventSegmentCalcs.new(event)
    @ordered_splits = ordered_split_array || event.ordered_splits.to_a
    @effort = event.efforts.find_by_bib_number(params[:bibNumber])
    @split = @ordered_splits.select { |split| split.id == params[:splitId].to_i }.first
    @day_and_time_in = (@effort && @split && params[:timeIn].present?) ? @effort.likely_intended_time(params[:timeIn], split, calcs) : nil
    @day_and_time_out = (@effort && @split && params[:timeOut].present?) ? @effort.likely_intended_time(params[:timeOut], split, calcs) : nil
    set_response_attributes
    verify_time_existence if (effort && split)
    verify_time_status if (effort && split && (day_and_time_in || day_and_time_out))
  end

  def success?
    (effort.present? && split.present?)
  end

  def split_id
    split ? split.id : nil
  end

  def effort_id
    effort ? effort.id : nil
  end

  def effort_name
    effort ? effort.full_name : nil
  end

  private

  attr_accessor :split_times_hash
  attr_reader :calcs, :ordered_splits, :split, :day_and_time_in, :day_and_time_out

  def set_response_attributes
    last_split_time = effort ? effort.last_reported_split_time : nil
    self.last_day_and_time = (effort && last_split_time) ? effort.start_time + last_split_time.time_from_start : nil
    self.last_split = last_split_time ? last_split_time.split : nil
    self.last_bitkey = last_split_time ? last_split_time.sub_split_bitkey : nil
    self.dropped = effort ? effort.dropped? : nil
    self.finished = effort ? effort.finished? : nil
    self.time_from_start_in = (effort && day_and_time_in) ? day_and_time_in - effort.start_time : nil
    self.time_from_last = (time_from_start_in && last_split_time) ? time_from_start_in - last_split_time.time_from_start : nil
    self.time_from_start_out = (effort && day_and_time_out) ? day_and_time_out - effort.start_time : nil
    self.time_in_aid = (time_from_start_out && time_from_start_in) ? time_from_start_out - time_from_start_in : nil
  end
  
  def verify_time_existence

    # Get all the split_times for this effort, which may or may not include
    # existing split_times corresponding to the effort + split being verified

    self.split_times_hash = effort.split_times.index_by(&:bitkey_hash)
    bitkey_hash_in = {split_id => SubSplit::IN_BITKEY}
    bitkey_hash_out = {split_id => SubSplit::OUT_BITKEY}

    # Set 'exists' booleans based on whether times for this effort + split
    # already exist in the database

    if split_times_hash[bitkey_hash_in].present?
      self.time_in_exists = true
      self.existing_time_in_id = split_times_hash[bitkey_hash_in].id
    else
      self.time_in_exists = false
      self.existing_time_in_id = nil
    end

    if split_times_hash[bitkey_hash_out].present?
      self.time_out_exists = true
      self.existing_time_out_id = split_times_hash[bitkey_hash_out].id
    else
      self.time_out_exists = false
      self.existing_time_out_id = nil
    end
  end

  def verify_time_status

    # Build in and/or out SplitTime instances (depending on availability of time data)
    # for temporary use in determining status of entered times.

    split_time_in = time_from_start_in ?
        SplitTime.new(effort_id: effort_id,
                      split_id: split_id,
                      sub_split_bitkey: SubSplit::IN_BITKEY,
                      time_from_start: time_from_start_in) :
        nil
    split_time_out = time_from_start_out ?
        SplitTime.new(effort_id: effort.id,
                      split_id: split_id,
                      sub_split_bitkey: SubSplit::OUT_BITKEY,
                      time_from_start: time_from_start_out) :
        nil
    bitkey_hash_in = split_time_in ? split_time_in.bitkey_hash : nil
    bitkey_hash_out = split_time_out ? split_time_out.bitkey_hash : nil

    # Now insert new SplitTime instances into hash table (or change existing ones)

    split_times_hash[bitkey_hash_in] = split_time_in if split_time_in
    split_times_hash[bitkey_hash_out] = split_time_out if split_time_out

    # Use ordered_bitkey_hashes as a framework to collect split_times into correct order

    ordered_bitkey_hashes = ordered_splits.map(&:sub_split_bitkey_hashes).flatten
    ordered_split_times = ordered_bitkey_hashes.collect { |key_hash| split_times_hash[key_hash] }

    # Now determine data status of each object in the ordered split_time group,
    # including our new in and/or out SplitTime instances

    status_hash = DataStatusService.live_entry_data_status(self, ordered_split_times.compact, calcs, ordered_splits)

    # And save the data status of the new SplitTime instances

    self.time_in_status = status_hash[bitkey_hash_in]
    self.time_out_status = status_hash[bitkey_hash_out]
  end

end
