# frozen_string_literal: true

class SplitTimeParameters < BaseParameters

  def self.permitted
    [:id, :effort_id, :lap, :split_id, :bitkey, :sub_split_bitkey, :time_from_start, :absolute_time, :absolute_time_local,
     :stopped_here, :elapsed_time, :time_of_day, :military_time, :data_status, :imposed_order, :matching_raw_time_id]
  end

  def self.unique_key
    [:effort_id, :lap, :split_id, :sub_split_bitkey]
  end
end
