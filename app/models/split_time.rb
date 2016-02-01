class SplitTime < ActiveRecord::Base
  enum data_status: [:wrong, :questionable, :good]
  validates_presence_of :effort_id, :split_id, :time_from_start
  validates_uniqueness_of :split_id, scope: :effort_id
  validates_uniqueness_of :effort_id, scope: :split_id
  belongs_to :effort
  belongs_to :split
end
