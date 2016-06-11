class LiveEffortData

  attr_accessor :time_from_start_in, :time_from_start_out, :time_from_last, :last_day_and_time,
                :time_in_aid, :dropped, :finished, :last_split, :last_bitkey,
                :time_in_exists, :time_out_exists, :time_in_status, :time_out_status
  attr_reader :effort

  def initialize(event, params)
    @calcs = EventSegmentCalcs.new(event)
    @effort = event.efforts.find_by_bib_number(params[:bibNumber])
    @ordered_splits = event.splits.ordered.to_a
    @split = @ordered_splits.select { |split| split.id == params[:splitId].to_i }.first
    @day_and_time_in = (@effort && @split && params[:timeIn].present?) ? @effort.likely_intended_time(params[:timeIn], split, calcs) : nil
    @day_and_time_out = (@effort && @split && params[:timeOut].present?) ? @effort.likely_intended_time(params[:timeOut], split, calcs) : nil
    set_response_attributes
    verify_time_data if (effort && split && (day_and_time_in || day_and_time_out))
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

  def verify_time_data
    split_times_hash = effort.split_times.index_by(&:bitkey_hash)
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
    self.time_in_exists = bitkey_hash_in ? split_times_hash[bitkey_hash_in].present? : nil
    self.time_out_exists = bitkey_hash_out ? split_times_hash[bitkey_hash_out].present? : nil
    split_times_hash[bitkey_hash_in] = split_time_in if split_time_in
    split_times_hash[bitkey_hash_out] = split_time_out if split_time_out
    ordered_bitkey_hashes = ordered_splits.map(&:sub_split_bitkey_hashes).flatten
    ordered_split_times = ordered_bitkey_hashes.collect { |key_hash| split_times_hash[key_hash] }
    status_hash = DataStatusService.live_entry_data_status(self, ordered_split_times.compact, calcs, ordered_splits)
    self.time_in_status = status_hash[bitkey_hash_in]
    self.time_out_status = status_hash[bitkey_hash_out]
  end

end
