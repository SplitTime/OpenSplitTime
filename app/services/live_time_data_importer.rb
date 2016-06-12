class LiveTimeDataImporter

  attr_accessor :data_objects

  def initialize(event, time_data_rows)
    @event = event
    @time_data_rows = time_data_rows
    create_data_objects
    create_split_times
  end

  private

  attr_reader :event, :time_data_rows

  def create_data_objects
    calcs = EventSegmentCalcs.new(event)
    splits = event.ordered_splits.to_a
    self.data_objects = []
    time_data_rows.each do |row|
      data_object = LiveEffortData.new(event, row, calcs, splits)
      data_objects << data_object
    end
  end

  def create_split_times
    new_split_time_array = []
    existing_split_time_hash = {}
    data_objects.each do |data_object|
      if data_object.time_from_start_in.present?
        split_time_data = {
            split_id: data_object.split_id,
            effort_id: data_object.effort_id,
            time_from_start: data_object.time_from_start_in,
            sub_split_bitkey: SubSplit::IN_BITKEY,
            data_status: data_object.time_in_status
        }
        if data_object.time_in_exists
          existing_split_time_hash[data_object.existing_time_in_id] = split_time_data
        else
          new_split_time_array << split_time_data
        end
      end
      if data_object.time_from_start_out.present?
        split_time_data = {
            split_id: data_object.split_id,
            effort_id: data_object.effort_id,
            time_from_start: data_object.time_from_start_out,
            sub_split_bitkey: SubSplit::OUT_BITKEY,
            data_status: data_object.time_out_status
        }
        if data_object.time_out_exists
          existing_split_time_hash[data_object.existing_time_out_id] = split_time_data
        else
          new_split_time_array << split_time_data
        end
      end
    end
  end

end