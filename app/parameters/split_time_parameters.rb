# frozen_string_literal: true

class SplitTimeParameters < BaseParameters

  def self.permitted
    [:id, :effort_id, :lap, :split_id, :time_from_start, :bitkey, :sub_split_bitkey,
     :stopped_here, :elapsed_time, :time_of_day, :military_time, :data_status, :imposed_order]
  end

  def self.unique_key
    [:effort_id, :lap, :split_id, :sub_split_bitkey]
  end
end
