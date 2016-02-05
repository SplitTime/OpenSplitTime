class SplitTime < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good]   # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  validates_presence_of :effort_id, :split_id, :time_from_start
  validates_uniqueness_of :split_id, scope: :effort_id, :message => "only one of any given split permitted within an effort"
  belongs_to :effort
  belongs_to :split
end
