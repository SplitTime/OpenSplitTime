class SplitRow
  attr_accessor :split_id, :base_name, :name_extension, :distance_from_start, :sub_split_mask,
                :time_from_start, :data_status, :kind, :segment_time

  def initialize(row_data, prior_time = nil)
    @split_id = row_data[:id]
    @base_name = row_data[:base_name]
    @name_extension = row_data[:name_extension]
    @distance_from_start = row_data[:distance_from_start]
    @sub_split_mask = row_data[:sub_split_mask]
    @kind = row_data[:kind]
    if row_data[:time_from_start]
      @time_from_start = row_data[:time_from_start]
      @data_status = row_data[:data_status]
      @segment_time = prior_time ? @time_from_start - prior_time : 0
    end
  end

end