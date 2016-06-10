class ManualSplitTimeImporter

  def initialize(event, time_data_rows)
    @event = event
    @time_data_rows = time_data_rows
    create_split_times
  end

  def create_split_times
    time_data_rows.each do |row|
      split_time_in = SplitTime.new(effort_id: row.effortId,
                                    split_id: row.splitId,
                                    sub_split_bitkey_hash: SubSplit::IN_BITKEY,
                                    time_from_start: row.timeFromStartIn)
      split_time_out = SplitTime.new(effort_id: row.effortId,
                                     split_id: row.splitId,
                                     sub_split_bitkey_hash: SubSplit::OUT_BITKEY,
                                     time_from_start: row.timeFromStartOut)
    end
  end

end