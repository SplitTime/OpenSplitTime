class SplitTimeParameters < BaseParameters

  def self.permitted
    [:id, :effort_id, :lap, :split_id, :time_from_start, :bitkey, :sub_split_bitkey,
     :stopped_here, :elapsed_time, :time_of_day, :military_time, :data_status]
  end
end
