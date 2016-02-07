class SplitTime < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good]   # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :effort
  belongs_to :split

  validates_presence_of :effort_id, :split_id, :time_from_start
  validates_uniqueness_of :split_id, scope: :effort_id, :message => "only one of any given split permitted within an effort"
  validates_numericality_of :time_from_start, equal_to: 0, :if => 'split_is_start?', :message => "the starting split_time must have 0 time from start"

  def split_is_start?
    split_id.nil? ? false : split.kind == "start"
  end

end
